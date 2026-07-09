defmodule Glossia.TranslationSessions.TranslateTest do
  use Glossia.DataCase, async: false
  use Mimic

  alias Glossia.Github.Installations
  alias Glossia.Projects
  alias Glossia.Repo
  alias Glossia.TestHelpers
  alias Glossia.TranslationSessions
  alias Glossia.TranslationSessions.Translate
  alias Glossia.TranslationSessions.TranslationSession

  # Translation now runs natively in Elixir (Glossia.Translations.RepositoryRun,
  # in a FLAME runner) and its change list feeds the existing GitHub-API PR
  # builder. These tests stub RepositoryRun.run/4 and exercise the PR/outcome path.

  defp project_with_installation(email, handle) do
    user = TestHelpers.create_user(email, handle)

    {:ok, installation} =
      Installations.create_installation(user.account, %{
        github_installation_id: 42,
        github_account_login: "glossia",
        github_account_type: "Organization",
        github_account_id: 4242
      })

    {:ok, project} =
      Projects.create_project_from_github(user.account, installation.id, %{
        handle: "#{handle}-project",
        name: "Project",
        github_repo_full_name: "glossia/demo",
        github_repo_default_branch: "main",
        setup_target_languages: ["es"]
      })

    {user, project}
  end

  defp session_for(user, project) do
    {:ok, session} =
      TranslationSessions.create_session(user.account, project, %{
        commit_sha: "abc1234567890",
        commit_message: "Add guide",
        source_language: "en",
        target_languages: ["es"]
      })

    session
  end

  defp stub_run(changes) do
    Mimic.stub(Glossia.Translations.RepositoryRun, :run, fn _session, _account, _repository, _locales ->
      {:ok, changes}
    end)
  end

  test "opens a pull request from the translated change list" do
    {user, project} = project_with_installation("translate@test.com", "translate")
    session = session_for(user, project)
    test_pid = self()

    stub_run([
      %{path: "docs/i18n/es/guide.md", status: "added", content: "# Hola mundo\n"},
      %{path: ".glossia/docs/guide.md/es.lock", status: "added", content: "{}"}
    ])

    Mimic.stub(Glossia.Github.App, :installation_token, fn 42 -> {:ok, "github-token"} end)

    Mimic.expect(Glossia.Github.Client, :get_commit, fn "glossia/demo", "abc1234567890", "github-token" ->
      {:ok, %{"tree" => %{"sha" => "base-tree-sha"}}}
    end)

    Mimic.expect(Glossia.Github.Client, :create_blob, 2, fn "glossia/demo", %{content: content, encoding: "base64"}, "github-token" ->
      {:ok, decoded} = Base.decode64(content)
      {:ok, %{"sha" => :crypto.hash(:sha, decoded) |> Base.encode16(case: :lower)}}
    end)

    Mimic.expect(Glossia.Github.Client, :create_tree, fn "glossia/demo", %{base_tree: "base-tree-sha", tree: entries}, "github-token" ->
      send(test_pid, {:tree_entries, entries})
      {:ok, %{"sha" => "new-tree-sha"}}
    end)

    Mimic.expect(Glossia.Github.Client, :create_commit, fn "glossia/demo", %{tree: "new-tree-sha", parents: ["abc1234567890"]} = _params, "github-token" ->
      {:ok, %{"sha" => "new-commit-sha"}}
    end)

    Mimic.expect(Glossia.Github.Client, :create_branch, fn "glossia/demo", "glossia/translate-abc123456789", "new-commit-sha", "github-token" ->
      {:ok, %{}}
    end)

    Mimic.expect(Glossia.Github.Client, :create_pull_request, fn "glossia/demo", params, "github-token" ->
      send(test_pid, {:pull_request_params, params})
      {:ok, %{"html_url" => "https://github.com/glossia/demo/pull/2"}}
    end)

    assert :ok = Translate.run(session.id)

    assert_received {:tree_entries, entries}

    assert Enum.map(entries, & &1.path) == [
             "docs/i18n/es/guide.md",
             ".glossia/docs/guide.md/es.lock"
           ]

    assert_received {:pull_request_params, params}
    assert params.title == "feat: translate content for abc1234"

    updated = Repo.get!(TranslationSession, session.id)
    assert updated.status == "completed"
    assert updated.summary == "Created translation pull request."
  end

  test "completes without a PR when there are no changes" do
    {user, project} = project_with_installation("translate-empty@test.com", "translate-empty")
    session = session_for(user, project)

    Mimic.stub(Glossia.Github.App, :installation_token, fn 42 -> {:ok, "github-token"} end)
    stub_run([])

    assert :ok = Translate.run(session.id)

    updated = Repo.get!(TranslationSession, session.id)
    assert updated.status == "completed"
    assert updated.summary == "No translations needed."
  end

  test "fails the session when the repository run fails" do
    {user, project} = project_with_installation("translate-fail@test.com", "translate-fail")
    session = session_for(user, project)

    Mimic.stub(Glossia.Github.App, :installation_token, fn 42 -> {:ok, "github-token"} end)

    Mimic.stub(Glossia.Translations.RepositoryRun, :run, fn _session, _account, _repository, _locales ->
      {:error, {:clone_failed, "boom"}}
    end)

    assert {:error, {:clone_failed, "boom"}} = Translate.run(session.id)

    updated = Repo.get!(TranslationSession, session.id)
    assert updated.status == "failed"
  end
end
