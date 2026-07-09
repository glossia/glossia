defmodule Glossia.Translations.LiveTranslationTest do
  @moduledoc """
  Full-chain local verification: the real `RepositoryRun` pipeline against a real
  git working tree, translating through the local Claude Code session (no stub,
  real Anthropic call). Excluded from normal runs (`:live` tag) — run explicitly:

      mix test --include live test/glossia/translations/live_translation_test.exs
  """
  use Glossia.DataCase, async: false

  alias Glossia.Translations.Credentials
  alias Glossia.Translations.RepositoryRun
  alias Glossia.TestHelpers
  alias Glossia.TranslationSessions.TranslationSession

  @moduletag :live

  setup do
    previous = Application.get_env(:glossia, Glossia.Translations, [])
    Application.put_env(:glossia, Glossia.Translations, allow_local_session: true)
    on_exit(fn -> Application.put_env(:glossia, Glossia.Translations, previous) end)
    :ok
  end

  defp git!(root, args),
    do: {_out, 0} = MuonTrap.cmd("git", ["-C", root | args], stderr_to_stdout: true, into: "")

  @tag :tmp_dir
  test "translates a repo end-to-end using the local Claude session", %{tmp_dir: root} do
    # Requires a valid local Claude Code session.
    if is_nil(Credentials.claude_session()) do
      flunk("No valid local Claude session found — log in to Claude Code first.")
    end

    git!(root, ["init", "-q"])
    git!(root, ["config", "user.email", "t@example.com"])
    git!(root, ["config", "user.name", "Tester"])

    File.write!(Path.join(root, "GLOSSIA.md"), """
    ---
    source_language: en
    model: openai/gpt-5
    sources:
      "docs/*.md": "docs/i18n/{locale}/*.md"
    targets:
      es: Spanish
    ---
    Project context
    """)

    File.mkdir_p!(Path.join(root, "docs"))
    File.write!(Path.join([root, "docs", "guide.md"]), "# Guide\n\nHello, world.")
    git!(root, ["add", "."])
    git!(root, ["commit", "-q", "-m", "init"])

    user = TestHelpers.create_user("live-translate@test.com", "live-translate")
    session = %TranslationSession{id: Ecto.UUID.generate()}

    assert {:ok, changes} = RepositoryRun.translate_repository(session, user.account, root, ["es"])

    output = Path.join([root, "docs", "i18n", "es", "guide.md"])
    assert File.exists?(output)
    translated = File.read!(output)
    IO.puts("\n--- Translated docs/i18n/es/guide.md ---\n#{translated}\n----------------------------------------")

    # Real Spanish output + a change list with the file and its lockfile.
    assert translated =~ ~r/hola/i
    paths = changes |> Enum.map(& &1.path) |> Enum.sort()
    assert "docs/i18n/es/guide.md" in paths
    assert ".glossia/docs/guide.md/es.lock" in paths
  end

  @tag :tmp_dir
  test "runs the whole thing through FLAME.call, cloning a local seeded remote", %{tmp_dir: root} do
    if is_nil(Credentials.claude_session()) do
      flunk("No valid local Claude session found — log in to Claude Code first.")
    end

    # Share the sandbox connection so the FLAME.call'd process can query the DB.
    Ecto.Adapters.SQL.Sandbox.mode(Glossia.Repo, {:shared, self()})

    # A local "remote" that stands in for GitHub (what seeds.exs sets up in dev).
    remotes = Path.join(root, "remotes")
    remote = Path.join([remotes, "glossia", "demo"])
    File.mkdir_p!(remote)
    git!(remote, ["init", "-q", "-b", "main"])
    git!(remote, ["config", "user.email", "t@example.com"])
    git!(remote, ["config", "user.name", "Tester"])

    File.write!(Path.join(remote, "GLOSSIA.md"), """
    ---
    source_language: en
    model: openai/gpt-5
    sources:
      "docs/*.md": "docs/i18n/{locale}/*.md"
    targets:
      es: Spanish
    ---
    Project context
    """)

    File.mkdir_p!(Path.join(remote, "docs"))
    File.write!(Path.join([remote, "docs", "guide.md"]), "# Guide\n\nHello, world.")
    git!(remote, ["add", "."])
    git!(remote, ["commit", "-q", "-m", "init"])

    Application.put_env(:glossia, Glossia.Translations,
      allow_local_session: true,
      local_remotes_dir: remotes
    )

    user = TestHelpers.create_user("live-flame@test.com", "live-flame")
    session = %TranslationSession{id: Ecto.UUID.generate()}

    repository = %{full_name: "glossia/demo", default_branch: "main", commit_sha: nil, token: "x"}

    assert {:ok, changes} = RepositoryRun.run(session, user.account, repository, ["es"])

    output = Enum.find(changes, &(&1.path == "docs/i18n/es/guide.md"))
    assert output
    IO.puts("\n--- FLAME.call e2e: docs/i18n/es/guide.md ---\n#{output.content}\n---------------------------------------------")
    assert output.content =~ ~r/hola/i
  end
end
