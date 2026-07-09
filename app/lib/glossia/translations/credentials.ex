defmodule Glossia.Translations.Credentials do
  @moduledoc """
  Resolves the effective model + auth for a translation, in precedence order:

    1. The account's `LLMModel` (per-account API key) — normal production path.
    2. A globally configured inference provider (token + URL) — the production
       fallback described as "a token of an inference provider and an URL".
    3. In development only, the local Claude Code or Codex CLI session (whichever
       is valid) — so you can run real translations without configuring a key.

  Returns a credential map:

      %{model: "provider:model", auth: auth, source: atom}

  where `auth` is `{:api_key, key, base_url_or_nil}` (used via Condukt) or
  `{:oauth, access_token}` (used via ReqLLM directly, since Condukt can't carry
  OAuth). Local sessions are OAuth tokens, so they take the `:oauth` path.
  """

  alias Glossia.Accounts.Account
  alias Glossia.LLMModels

  @default_local_model "anthropic:claude-haiku-4-5"

  @type auth :: {:api_key, String.t(), String.t() | nil} | {:oauth, String.t()}
  @type credential :: %{model: String.t(), auth: auth(), source: atom()}

  @spec resolve(Account.t(), String.t() | nil) ::
          {:ok, credential()} | {:error, {:model_not_found, String.t() | nil}}
  def resolve(%Account{} = account, model_handle) do
    cond do
      cred = account_model_credential(account, model_handle) -> {:ok, cred}
      cred = inference_config_credential() -> {:ok, cred}
      cred = local_session_credential() -> {:ok, cred}
      true -> {:error, {:model_not_found, model_handle}}
    end
  end

  # 1. Per-account model with its own API key.
  defp account_model_credential(account, model_handle) do
    case find_model(account, model_handle) do
      %{model: model, api_key: key} when is_binary(key) and key != "" ->
        %{model: model, auth: {:api_key, key, nil}, source: :account_model}

      _ ->
        nil
    end
  end

  defp find_model(account, handle) when is_binary(handle) and handle != "" do
    LLMModels.get_model_by_handle(handle, account.id) || LLMModels.default_model(account)
  end

  defp find_model(account, _handle), do: LLMModels.default_model(account)

  # 2. Globally configured inference provider (prod: token + URL).
  defp inference_config_credential do
    config = config()
    key = config[:inference_api_key]
    model = config[:inference_model]

    if present?(key) and present?(model) do
      %{
        model: model,
        auth: {:api_key, key, config[:inference_base_url]},
        source: :inference_config
      }
    end
  end

  # 3. Local Claude/Codex session (dev only).
  defp local_session_credential do
    if config()[:allow_local_session] do
      claude_session() || codex_session()
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
      %{model: local_model(), auth: {:oauth, token}, source: :claude_session}
    end
  end

  def claude_credential(_oauth), do: nil

  # Claude Code stores its OAuth credentials in the macOS keychain.
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
    with {:ok, raw} <- File.read(Path.expand(path)),
         {:ok, %{"tokens" => %{"access_token" => token}}} <- Jason.decode(raw),
         true <- present?(token) do
      %{model: local_model("openai:gpt-5"), auth: {:oauth, token}, source: :codex_session}
    else
      _ -> nil
    end
  end

  defp codex_auth_path do
    case System.get_env("CODEX_HOME") do
      home when is_binary(home) and home != "" -> Path.join(home, "auth.json")
      _ -> "~/.codex/auth.json"
    end
  end

  # `expiresAt` is epoch milliseconds; missing means treat as valid.
  defp not_expired?(nil), do: true

  defp not_expired?(expires_at) when is_integer(expires_at),
    do: expires_at > System.system_time(:millisecond)

  defp not_expired?(_), do: false

  defp local_model(default \\ @default_local_model), do: config()[:local_session_model] || default

  defp config, do: Application.get_env(:glossia, Glossia.Translations, [])

  defp present?(value), do: is_binary(value) and String.trim(value) != ""
end
