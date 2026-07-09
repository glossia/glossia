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
        "model" => "anthropic:claude-sonnet-4-20250514",
        "api_key" => "sk-account-key"
      })

    put_config([])

    assert {:ok, cred} = Credentials.resolve(account, "translator")
    assert cred.source == :account_model
    assert cred.model == "anthropic:claude-sonnet-4-20250514"
    assert cred.auth == {:api_key, "sk-account-key", nil}
  end

  test "falls back to the globally configured inference provider (token + URL)", %{account: account} do
    put_config(
      inference_model: "openai:gpt-5",
      inference_api_key: "sk-inference",
      inference_base_url: "https://inference.example/v1",
      allow_local_session: false
    )

    assert {:ok, cred} = Credentials.resolve(account, nil)
    assert cred.source == :inference_config
    assert cred.model == "openai:gpt-5"
    assert cred.auth == {:api_key, "sk-inference", "https://inference.example/v1"}
  end

  test "errors when nothing resolves and local sessions are disabled", %{account: account} do
    put_config(allow_local_session: false)
    assert {:error, {:model_not_found, "nope"}} = Credentials.resolve(account, "nope")
  end
end
