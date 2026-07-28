defmodule Glossia.TranslationSessions.TranslateTest do
  use Glossia.DataCase, async: true
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
    Mimic.stub(Glossia.Translations.RepositoryRun, :run, fn _session,
                                                            _account,
                                                            _repository,
                                                            _locales,
                                                            _opts ->
      {:ok, changes}
    end)
  end

  defp stub_published_run(payloads) do
    Mimic.stub(Glossia.Translations.RepositoryRun, :run, fn _session,
                                                            _account,
                                                            _repository,
                                                            _locales,
                                                            opts ->
      publication_target = Keyword.fetch!(opts, :publication_target)

      Enum.each(payloads, fn payload ->
        assert {:ok, _publication} =
                 publication_target.module.publish_item(
                   publication_target.context,
                   payload
                 )
      end)

      {:ok, Enum.flat_map(payloads, & &1.changes)}
    end)
  end

  test "opens a pull request from the translated change list" do
    {user, project} = project_with_installation("translate@test.com", "translate")
    session = session_for(user, project)
    test_pid = self()

    stub_published_run([
      %{
        output_path: "docs/i18n/es/guide.md",
        locale: "es",
        changes: [
          %{path: "docs/i18n/es/guide.md", status: "added", content: "# Hola mundo\n"},
          %{path: ".glossia/docs/guide.md/es.lock", status: "added", content: "{}"}
        ]
      },
      %{
        output_path: "docs/i18n/es/reference.md",
        locale: "es",
        changes: [
          %{path: "docs/i18n/es/reference.md", status: "added", content: "# Referencia\n"},
          %{path: ".glossia/docs/reference.md/es.lock", status: "added", content: "{}"}
        ]
      }
    ])

    Mimic.stub(Glossia.Github.App, :installation_token, fn 42 -> {:ok, "github-token"} end)

    Mimic.expect(Glossia.Github.Client, :get_commit, 2, fn "glossia/demo",
                                                           commit_sha,
                                                           "github-token" ->
      tree_sha =
        case commit_sha do
          "abc1234567890" -> "base-tree-sha"
          "first-commit-sha" -> "first-tree-sha"
        end

      {:ok, %{"tree" => %{"sha" => tree_sha}}}
    end)

    Mimic.expect(Glossia.Github.Client, :create_blob, 4, fn "glossia/demo",
                                                            %{
                                                              content: content,
                                                              encoding: "base64"
                                                            },
                                                            "github-token" ->
      {:ok, decoded} = Base.decode64(content)
      {:ok, %{"sha" => :crypto.hash(:sha, decoded) |> Base.encode16(case: :lower)}}
    end)

    Mimic.expect(Glossia.Github.Client, :create_tree, 2, fn "glossia/demo",
                                                            %{
                                                              base_tree: base_tree,
                                                              tree: entries
                                                            },
                                                            "github-token" ->
      send(test_pid, {:tree_entries, entries})

      tree_sha =
        case base_tree do
          "base-tree-sha" -> "first-tree-sha"
          "first-tree-sha" -> "second-tree-sha"
        end

      {:ok, %{"sha" => tree_sha}}
    end)

    Mimic.expect(Glossia.Github.Client, :create_commit, 2, fn "glossia/demo",
                                                              %{
                                                                tree: tree_sha,
                                                                parents: [parent_sha]
                                                              },
                                                              "github-token" ->
      commit_sha =
        case {tree_sha, parent_sha} do
          {"first-tree-sha", "abc1234567890"} -> "first-commit-sha"
          {"second-tree-sha", "first-commit-sha"} -> "second-commit-sha"
        end

      {:ok, %{"sha" => commit_sha}}
    end)

    Mimic.expect(Glossia.Github.Client, :create_branch, fn "glossia/demo",
                                                           "glossia/translate-abc123456789",
                                                           "first-commit-sha",
                                                           "github-token" ->
      {:ok, %{}}
    end)

    Mimic.expect(Glossia.Github.Client, :update_ref, fn "glossia/demo",
                                                        "heads/glossia/translate-abc123456789",
                                                        "second-commit-sha",
                                                        "github-token" ->
      {:ok, %{}}
    end)

    Mimic.expect(Glossia.Github.Client, :create_pull_request, fn "glossia/demo",
                                                                 params,
                                                                 "github-token" ->
      send(test_pid, {:pull_request_params, params})
      {:ok, %{"html_url" => "https://github.com/glossia/demo/pull/2"}}
    end)

    assert :ok = Translate.run(session.id)

    assert_received {:tree_entries, entries}

    assert Enum.map(entries, & &1.path) == [
             "docs/i18n/es/guide.md",
             ".glossia/docs/guide.md/es.lock"
           ]

    assert_received {:tree_entries, entries}

    assert Enum.map(entries, & &1.path) == [
             "docs/i18n/es/reference.md",
             ".glossia/docs/reference.md/es.lock"
           ]

    assert_received {:pull_request_params, params}
    assert params.title == "feat: translate content for abc1234"

    updated = Repo.get!(TranslationSession, session.id)
    assert updated.status == "completed"
    assert updated.summary == "Created translation pull request."
    assert updated.publication_branch == "glossia/translate-abc123456789"
    assert updated.publication_commit_sha == "second-commit-sha"
    assert updated.pull_request_url == "https://github.com/glossia/demo/pull/2"
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

    Mimic.stub(Glossia.Translations.RepositoryRun, :run, fn _session,
                                                            _account,
                                                            _repository,
                                                            _locales,
                                                            _opts ->
      {:error, {:clone_failed, "boom"}}
    end)

    assert {:error, {:clone_failed, "boom"}} = Translate.run(session.id)

    updated = Repo.get!(TranslationSession, session.id)
    assert updated.status == "failed"
  end

  test "keeps a failed attempt running while the worker can still retry" do
    {user, project} =
      project_with_installation("translate-retry@test.com", "translate-retry")

    session = session_for(user, project)

    Mimic.stub(Glossia.Github.App, :installation_token, fn 42 -> {:ok, "github-token"} end)

    Mimic.stub(Glossia.Translations.RepositoryRun, :run, fn _session,
                                                            _account,
                                                            _repository,
                                                            _locales,
                                                            _opts ->
      {:error, {:translation_items_failed, [%{output_path: "docs/es/guide.md"}]}}
    end)

    assert {:error, {:translation_items_failed, [_failure]}} =
             Translate.run(session.id, terminal_failure?: false)

    updated = Repo.get!(TranslationSession, session.id)
    assert updated.status == "running"
    assert is_nil(updated.error)
    assert is_nil(updated.completed_at)
  end

  test "starting a retry clears fields from the previous failed attempt" do
    {user, project} =
      project_with_installation("translate-reset@test.com", "translate-reset")

    session = session_for(user, project)

    {:ok, failed_session} =
      TranslationSessions.update_session_status(session, "failed",
        error: "Previous failure",
        summary: "Previous summary"
      )

    assert failed_session.completed_at

    {:ok, running_session} =
      TranslationSessions.update_session_status(failed_session, "running")

    assert running_session.status == "running"
    assert running_session.started_at
    assert is_nil(running_session.completed_at)
    assert is_nil(running_session.error)
    assert is_nil(running_session.summary)
  end

  test "fails the session when the isolated repository run returns an exit" do
    {user, project} = project_with_installation("translate-exit@test.com", "translate-exit")
    session = session_for(user, project)

    Mimic.stub(Glossia.Github.App, :installation_token, fn 42 -> {:ok, "github-token"} end)

    Mimic.stub(Glossia.Translations.RepositoryRun, :run, fn _session,
                                                            _account,
                                                            _repository,
                                                            _locales,
                                                            _opts ->
      {:error, {:runner_exit, %ArgumentError{message: "runner event broadcaster is unavailable"}}}
    end)

    assert {:error, {:runner_exit, %ArgumentError{}}} = Translate.run(session.id)

    updated = Repo.get!(TranslationSession, session.id)
    assert updated.status == "failed"

    assert updated.error ==
             "Translation stopped unexpectedly in the isolated runner. Please retry."

    assert updated.completed_at
  end
end
