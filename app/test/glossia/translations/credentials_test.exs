defmodule Glossia.Translations.CredentialsTest do
  use Glossia.DataCase, async: false

  alias Glossia.LLMModels
  alias Glossia.Translations.Credentials
  alias Glossia.TestHelpers

  setup do
    user = TestHelpers.create_user("credentials@test.com", "credentials")
    previous = Application.get_env(:glossia, Glossia.Translations, [])
    on_exit(fn -> Application.put_env(:glossia, Glossia.Translations, previous) end)
    %{user: user, account: user.account}
  end

  defp put_config(kw), do: Application.put_env(:glossia, Glossia.Translations, kw)

  test "prefers the account model's own API key", %{user: user, account: account} do
    {:ok, _model} =
      LLMModels.create_model(account, user, %{
        "handle" => "translator",
        "model" => "anthropic/claude-sonnet-4-20250514",
        "api_key" => "sk-account-key"
      })

    put_config([])

    assert {:ok, cred} = Credentials.resolve(account, "translator")
    assert cred.source == :account_model
    assert cred.model == "anthropic/claude-sonnet-4-20250514"
    assert cred.handle == "translator"
    assert cred.auth == {:api_key, "sk-account-key", nil}
  end

  test "resolves credentials on the designated database node", %{
    user: user,
    account: account
  } do
    {:ok, _model} =
      LLMModels.create_model(account, user, %{
        "handle" => "isolated-translator",
        "model" => "anthropic/claude-sonnet-4-20250514",
        "api_key" => "sk-account-key"
      })

    assert {:ok, cred} = Credentials.resolve_on(Node.self(), account, "isolated-translator")
    assert cred.handle == "isolated-translator"
    assert cred.auth == {:api_key, "sk-account-key", nil}
  end

  test "returns a typed error when the database node is unavailable", %{account: account} do
    assert {:error, {:credential_relay_failed, _reason}} =
             Credentials.resolve_on(:"missing@127.0.0.1", account, "translator")
  end

  test "does not replace an unknown explicit handle with the account default", %{
    user: user,
    account: account
  } do
    {:ok, _default} =
      LLMModels.create_model(account, user, %{
        "handle" => "translation-default",
        "model" => "anthropic/claude-sonnet-4-20250514",
        "api_key" => "sk-account-key"
      })

    put_config(
      inference_model: "openai/gpt-5",
      inference_api_key: "sk-inference",
      allow_local_session: false
    )

    assert {:error, {:model_not_found, "misspelled-handle"}} =
             Credentials.resolve(account, "misspelled-handle")
  end

  test "falls back to the globally configured inference provider (token + URL)", %{
    account: account
  } do
    put_config(
      inference_model: "openai/gpt-5",
      inference_api_key: "sk-inference",
      inference_base_url: "https://inference.example/v1",
      allow_local_session: false
    )

    assert {:ok, cred} = Credentials.resolve(account, nil)
    assert cred.source == :inference_config
    assert cred.model == "openai/gpt-5"
    assert cred.handle == nil
    assert cred.auth == {:api_key, "sk-inference", "https://inference.example/v1"}
  end

  test "errors when nothing resolves and local sessions are disabled", %{account: account} do
    put_config(allow_local_session: false)
    assert {:error, {:model_not_found, "nope"}} = Credentials.resolve(account, "nope")
  end

  test "does not interpret development session sentinels when local sessions are disabled", %{
    user: user,
    account: account
  } do
    {:ok, _model} =
      LLMModels.create_model(account, user, %{
        "handle" => "forged-local-session",
        "model" => "openai/gpt-5.4",
        "api_key" => Credentials.development_session_api_key(:codex),
        "default" => true
      })

    put_config(allow_local_session: false)

    assert {:error, {:model_not_found, "forged-local-session"}} =
             Credentials.resolve(account, "forged-local-session")
  end

  test "builds a Codex setup session with refreshable credentials", %{account: _account} do
    path =
      Path.join(
        System.tmp_dir!(),
        "glossia-codex-auth-#{System.unique_integer([:positive])}.json"
      )

    auth = %{
      "auth_mode" => "chatgpt",
      "tokens" => %{
        "access_token" => "access-token",
        "refresh_token" => "refresh-token",
        "account_id" => "account-id"
      }
    }

    File.write!(path, JSON.encode!(auth))
    on_exit(fn -> File.rm(path) end)

    assert {:ok, credential} = Credentials.codex_cli_session(path, "openai/gpt-5.4")
    assert credential.harness == "codex"
    assert credential.command == "codex"
    assert credential.model == "gpt-5.4"
    assert credential.codex_auth == auth
  end
end
