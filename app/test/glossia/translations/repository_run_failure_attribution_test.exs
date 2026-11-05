defmodule Glossia.Translations.RepositoryRunFailureAttributionTest do
  use Glossia.DataCase, async: true
  use Mimic

  import ExUnit.CaptureLog

  alias Glossia.LLMModels
  alias Glossia.TestHelpers
  alias Glossia.Translations
  alias Glossia.Translations.Context
  alias Glossia.Translations.RepositoryRun
  alias Glossia.TranslationSessions.TranslationSession

  defp git!(root, args) do
    {_out, 0} =
      MuonTrap.cmd(
        "git",
        ["-c", "commit.gpgsign=false", "-c", "core.hooksPath=/dev/null", "-C", root | args],
        stderr_to_stdout: true,
        into: "",
        timeout: 10_000
      )
  end

  @tag :tmp_dir
  test "attributes provider failures to the account default model when L10N.md names none", %{
    tmp_dir: root
  } do
    user = TestHelpers.create_user("attribution@test.com", "attribution")

    {:ok, _model} =
      LLMModels.create_model(user.account, user, %{
        "handle" => "gateway",
        "model" => "openai/Translator",
        "api_key" => "sk-gateway",
        "base_url" => "https://gateway.example.com/v1",
        "default" => true
      })

    git!(root, ["init", "-q"])

    File.write!(Path.join(root, "L10N.md"), """
    ---
    source_language: en
    sources:
      "docs/*.md": "docs/i18n/{locale}/*.md"
    targets:
      es: Spanish
    ---
    """)

    File.mkdir_p!(Path.join(root, "docs"))
    File.write!(Path.join([root, "docs", "guide.md"]), "# Guide\n\nHello, world.")

    Mimic.stub(Translations, :translate_stream, fn _account, _payload, _on_event, _opts ->
      {:error, %{reason: "Credit limit exceeded", status: 402}}
    end)

    session = %TranslationSession{id: Ecto.UUID.generate(), project_id: Ecto.UUID.generate()}

    {result, log} =
      with_log(fn ->
        RepositoryRun.translate_repository(session, user.account, root, ["es"],
          context_snapshot: Context.empty_snapshot()
        )
      end)

    assert {:error, {:translation_items_failed, [failure]}} = result
    assert %{kind: "provider-credit", provider: "openai"} = failure.reason
    assert %{model: "openai/Translator", provider: "openai"} = failure.diagnostics
    assert log =~ ~s("model":"openai/Translator")
    assert log =~ ~s("provider":"openai")
  end
end
