defmodule Glossia.Translations.Credentials do
  @moduledoc """
  Resolves the effective model and authorization for a translation.

  When the repository names a model handle, that exact account model must
  resolve. An unknown explicit handle is an error and never falls back to
  another credential.

  When the repository omits a model handle, resolution follows this precedence:

    1. The account's `LLMModel` and provider key, which is the normal production path.
    2. A globally configured inference provider token and endpoint, which is the
       production fallback.
    3. In development only, the local Claude Code or Codex command-line session,
       whichever is valid, so real translations can run without configuring a key.

  Returns a credential map:

      %{model: "provider/model", handle: "account-handle", auth: auth, source: atom}

  where `auth` is `{:api_key, key, base_url_or_nil}` (used via Condukt) or
  `{:oauth, access_token}` (used via ReqLLM directly, since Condukt cannot carry
  [Open Authorization](https://oauth.net/2/) tokens). Local sessions use the
  `:oauth` path.
  """

  alias Glossia.Accounts.Account
  alias Glossia.LLMModels
  alias Glossia.Models.ModelIdentifier

  @default_local_model "anthropic/claude-haiku-4-5"
  @development_session_keys %{
    claude: "development-session:claude",
    codex: "development-session:codex"
  }

  @type auth :: {:api_key, String.t(), String.t() | nil} | {:oauth, String.t()}
  @type credential :: %{
          model: String.t(),
          handle: String.t() | nil,
          auth: auth(),
          source: atom()
        }

  @spec resolve(Account.t(), String.t() | nil) ::
          {:ok, credential()} | {:error, {:model_not_found, String.t() | nil}}
  def resolve(%Account{} = account, model_handle) do
    case normalized_handle(model_handle) do
      nil -> resolve_default(account, model_handle)
      handle -> resolve_explicit(account, handle)
    end
  end

  @doc """
  Resolves a credential on the node that owns the account database connection.

  Isolated translation runners deliberately do not start the repository or
  inherit database secrets. They use this function to ask the parent node for
  the credential required by a planned work item.
  """
  @spec resolve_on(node(), Account.t(), String.t() | nil) ::
          {:ok, credential()}
          | {:error, {:model_not_found, String.t() | nil}}
          | {:error, {:credential_relay_failed, term()}}
  def resolve_on(target_node, %Account{} = account, model_handle)
      when target_node == node() do
    resolve(account, model_handle)
  end

  def resolve_on(target_node, %Account{} = account, model_handle)
      when is_atom(target_node) do
    case :rpc.call(target_node, __MODULE__, :resolve, [account, model_handle], 5_000) do
      {:badrpc, reason} -> {:error, {:credential_relay_failed, reason}}
      result -> result
    end
  end

  @doc false
  def development_session_api_key(source) when source in [:claude, :codex],
    do: Map.fetch!(@development_session_keys, source)

  @doc """
  Resolves a credential into the files the setup assistant needs inside an
  ephemeral sandbox. Development session secrets are read at runtime and are
  never stored in the account model row.
  """
  def setup_harness_credential(%Account{} = account) do
    case resolve(account, nil) do
      {:ok, %{auth: {:api_key, key, base_url}} = credential} ->
        {:ok, api_key_harness_credential(credential, key, base_url)}

      {:ok, %{source: :codex_session, model: model}} ->
        codex_cli_session(codex_auth_path(), model)

      {:ok, %{source: :claude_session, model: model}} ->
        with {:ok, oauth} <- read_claude_oauth() do
          claude_cli_session(oauth, model)
        else
          :error -> {:error, :claude_session_not_available}
        end

      {:error, _reason} = error ->
        error
    end
  end

  defp resolve_explicit(account, handle) do
    case LLMModels.get_model_by_handle(handle, account.id) do
      nil ->
        {:error, {:model_not_found, handle}}

      model ->
        case account_model_credential(model) do
          nil -> {:error, {:model_not_found, handle}}
          credential -> {:ok, credential}
        end
    end
  end

  defp resolve_default(account, requested_handle) do
    cond do
      credential = account |> LLMModels.default_model() |> account_model_credential() ->
        {:ok, credential}

      credential = inference_config_credential() ->
        {:ok, credential}

      credential = local_session_credential() ->
        {:ok, credential}

      true ->
        {:error, {:model_not_found, requested_handle}}
    end
  end

  # 1. Per-account model with its own provider key.
  defp account_model_credential(nil), do: nil

  defp account_model_credential(configured_model) do
    credential =
      case configured_model do
        %{model: model, api_key: key}
        when key in ["development-session:claude", "development-session:codex"] ->
          development_account_session(key, model)

        %{model: model, api_key: key} when is_binary(key) and key != "" ->
          %{
            model: ModelIdentifier.normalize(model),
            auth: {:api_key, key, nil},
            source: :account_model
          }

        _ ->
          nil
      end

    if credential, do: Map.put(credential, :handle, configured_model.handle)
  end

  defp normalized_handle(handle) when is_binary(handle) do
    case String.trim(handle) do
      "" -> nil
      trimmed -> trimmed
    end
  end

  defp normalized_handle(_handle), do: nil

  # 2. Globally configured inference provider.
  defp inference_config_credential do
    config = config()
    key = config[:inference_api_key]
    model = config[:inference_model]

    if present?(key) and present?(model) do
      %{
        model: ModelIdentifier.normalize(model),
        handle: nil,
        auth: {:api_key, key, config[:inference_base_url]},
        source: :inference_config
      }
    end
  end

  # 3. Local Claude/Codex session (dev only).
  defp local_session_credential do
    if config()[:allow_local_session] do
      codex_session() || claude_session()
    end
  end

  @doc false
  def claude_session do
    case read_claude_oauth() do
      {:ok, oauth} -> claude_credential(oauth)
      :error -> nil
    end
  end

  @doc """
  Builds a Claude credential from a decoded `claudeAiOauth` map, or nil when the
  token is missing or expired. Split from the keychain read so it can be tested
  without touching the keychain.
  """
  def claude_credential(oauth) when is_map(oauth) do
    token = oauth["accessToken"]

    if present?(token) and not_expired?(oauth["expiresAt"]) do
      %{model: local_model(), handle: nil, auth: {:oauth, token}, source: :claude_session}
    end
  end

  def claude_credential(_oauth), do: nil

  # Claude Code stores its Open Authorization credentials in the macOS keychain.
  defp read_claude_oauth do
    with {:unix, :darwin} <- :os.type(),
         {json, 0} <-
           MuonTrap.cmd(
             "security",
             ["find-generic-password", "-s", "Claude Code-credentials", "-w"],
             stderr_to_stdout: true,
             into: ""
           ),
         {:ok, %{"claudeAiOauth" => oauth}} <- Jason.decode(String.trim(json)) do
      {:ok, oauth}
    else
      _ -> :error
    end
  end

  @doc false
  def codex_session, do: codex_session(codex_auth_path())

  @doc """
  Builds a Codex credential from an `auth.json` at `path`, or nil when absent or
  malformed. Takes an explicit path so it can be tested against a fixture.
  """
  def codex_session(path) when is_binary(path) do
    with {:ok, %{"tokens" => %{"access_token" => token}}} <- read_codex_auth(path),
         true <- present?(token),
         true <- not_expired?(token_expiry_ms(token)) do
      %{
        model: local_model("openai/gpt-5"),
        handle: nil,
        auth: {:oauth, token},
        source: :codex_session
      }
    else
      _ -> nil
    end
  end

  @doc false
  def codex_cli_session(path, model) when is_binary(path) and is_binary(model) do
    with {:ok, %{"tokens" => %{"access_token" => access}} = auth} <- read_codex_auth(path),
         true <- present?(access) do
      {:ok,
       %{
         model: codex_model(model),
         harness: "codex",
         command: "codex",
         codex_auth: auth,
         opencode_config: %{},
         opencode_auth: %{},
         source: :codex_session
       }}
    else
      _ -> {:error, :codex_session_not_available}
    end
  end

  @doc false
  def claude_cli_session(oauth, model) when is_map(oauth) and is_binary(model) do
    case claude_credential(oauth) do
      %{source: :claude_session} ->
        {:ok,
         %{
           model: claude_model(model),
           harness: "claude",
           command: "claude",
           claude_auth: %{"claudeAiOauth" => oauth},
           opencode_config: %{},
           opencode_auth: %{},
           source: :claude_session
         }}

      nil ->
        {:error, :claude_session_not_available}
    end
  end

  @doc false
  def codex_opencode_session(path, model) when is_binary(path) and is_binary(model) do
    with {:ok, %{"tokens" => tokens}} <- read_codex_auth(path),
         access when is_binary(access) and access != "" <- tokens["access_token"] do
      auth =
        %{
          "type" => "oauth",
          "access" => access,
          "expires" => token_expiry_ms(access)
        }
        |> maybe_put("accountId", tokens["account_id"])

      {:ok,
       %{
         model: open_code_model(model),
         opencode_config: %{"model" => open_code_model(model)},
         opencode_auth: %{"openai" => auth},
         source: :codex_session
       }}
    else
      _ -> {:error, :codex_session_not_available}
    end
  end

  defp codex_auth_path do
    case System.get_env("CODEX_HOME") do
      home when is_binary(home) and home != "" -> Path.join(home, "auth.json")
      _ -> "~/.codex/auth.json"
    end
  end

  defp read_codex_auth(path) do
    with {:ok, raw} <- File.read(Path.expand(path)),
         {:ok, decoded} when is_map(decoded) <- Jason.decode(raw) do
      {:ok, decoded}
    else
      _ -> :error
    end
  end

  defp api_key_harness_credential(credential, key, base_url) do
    model = open_code_model(credential.model)
    [provider | _rest] = String.split(model, "/", parts: 2)

    options =
      %{"apiKey" => key}
      |> maybe_put("baseURL", base_url)

    %{
      model: model,
      opencode_config: %{
        "model" => model,
        "provider" => %{provider => %{"options" => options}}
      },
      opencode_auth: %{},
      source: credential.source
    }
  end

  defp open_code_model(model), do: ModelIdentifier.normalize(model)

  defp codex_model(model), do: ModelIdentifier.provider_model(model)

  defp claude_model(model), do: ModelIdentifier.provider_model(model)

  defp token_expiry_ms(token) do
    with [_header, payload, _signature] <- String.split(token, "."),
         {:ok, decoded} <- Base.url_decode64(payload, padding: false),
         {:ok, %{"exp" => expires}} when is_integer(expires) <- Jason.decode(decoded) do
      expires * 1_000
    else
      _ -> System.system_time(:millisecond) + :timer.minutes(5)
    end
  end

  defp with_model(nil, _model), do: nil

  defp with_model(credential, model),
    do: %{credential | model: ModelIdentifier.normalize(model)}

  defp development_account_session(key, model) do
    if config()[:allow_local_session] do
      session =
        case key do
          "development-session:claude" -> claude_session()
          "development-session:codex" -> codex_session()
        end

      with_model(session, model)
    end
  end

  defp maybe_put(map, _key, value) when value in [nil, ""], do: map
  defp maybe_put(map, key, value), do: Map.put(map, key, value)

  # `expiresAt` is epoch milliseconds; missing means treat as valid.
  defp not_expired?(nil), do: true

  defp not_expired?(expires_at) when is_integer(expires_at),
    do: expires_at > System.system_time(:millisecond)

  defp not_expired?(_), do: false

  defp local_model(default \\ @default_local_model) do
    (config()[:local_session_model] || default)
    |> ModelIdentifier.normalize()
  end

  defp config, do: Application.get_env(:glossia, Glossia.Translations, [])

  defp present?(value), do: is_binary(value) and String.trim(value) != ""
end
