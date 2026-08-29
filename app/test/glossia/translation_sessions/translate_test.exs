defmodule Glossia.TranslationSessions.TranslateTest do
  use Glossia.DataCase, async: true
  use Mimic

  import ExUnit.CaptureLog

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

  test "opens a pull request from the translated change list" do
    {user, project} = project_with_installation("translate@test.com", "translate")
    session = session_for(user, project)
    test_pid = self()

    stub_run([
      %{path: "docs/i18n/es/guide.md", status: "added", content: "# Hola mundo\n"},
      %{path: ".glossia/docs/guide.md/es.lock", status: "added", content: "{}"},
      %{path: "docs/i18n/es/reference.md", status: "added", content: "# Referencia\n"},
      %{path: ".glossia/docs/reference.md/es.lock", status: "added", content: "{}"}
    ])

    Mimic.stub(Glossia.Github.App, :installation_token, fn 42 -> {:ok, "github-token"} end)

    Mimic.expect(Glossia.Github.Client, :get_commit, fn "glossia/demo",
                                                        "abc1234567890",
                                                        "github-token" ->
      {:ok, %{"tree" => %{"sha" => "base-tree-sha"}}}
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

    Mimic.expect(Glossia.Github.Client, :create_tree, fn "glossia/demo",
                                                         %{
                                                           base_tree: "base-tree-sha",
                                                           tree: entries
                                                         },
                                                         "github-token" ->
      send(test_pid, {:tree_entries, entries})

      {:ok, %{"sha" => "translation-tree-sha"}}
    end)

    Mimic.expect(Glossia.Github.Client, :create_commit, fn "glossia/demo",
                                                           %{
                                                             tree: "translation-tree-sha",
                                                             parents: ["abc1234567890"]
                                                           },
                                                           "github-token" ->
      {:ok, %{"sha" => "translation-commit-sha"}}
    end)

    Mimic.expect(Glossia.Github.Client, :create_branch, fn "glossia/demo",
                                                           "glossia/translate-abc123456789",
                                                           "translation-commit-sha",
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
             ".glossia/docs/guide.md/es.lock",
             "docs/i18n/es/reference.md",
             ".glossia/docs/reference.md/es.lock"
           ]

    assert_received {:pull_request_params, params}
    assert params.title == "feat: translate content for abc1234"

    updated = Repo.get!(TranslationSession, session.id)
    assert updated.status == "completed"
    assert updated.summary == "Created translation pull request."
    assert updated.publication_branch == "glossia/translate-abc123456789"
    assert updated.publication_commit_sha == "translation-commit-sha"
    assert updated.pull_request_url == "https://github.com/glossia/demo/pull/2"
  end

  test "publishes each completed file in its own commit" do
    {user, project} = project_with_installation("incremental-translate@test.com", "incremental")
    session = session_for(user, project)
    test_pid = self()

    first_changes = [
      %{path: "docs/i18n/es/guide.md", status: "added", content: "# Guía\n"},
      %{path: ".glossia/docs/guide.md/es.lock", status: "added", content: "{}"}
    ]

    second_changes = [
      %{path: "docs/i18n/es/reference.md", status: "added", content: "# Referencia\n"},
      %{path: ".glossia/docs/reference.md/es.lock", status: "added", content: "{}"}
    ]

    Mimic.stub(Glossia.Translations.RepositoryRun, :run, fn _session,
                                                            _account,
                                                            _repository,
                                                            _locales,
                                                            opts ->
      publish = Keyword.fetch!(opts, :after_item_completed)
      assert :ok = publish.(first_changes)
      assert :ok = publish.(second_changes)
      {:ok, first_changes ++ second_changes}
    end)

    Mimic.stub(Glossia.Github.App, :installation_token, fn 42 -> {:ok, "github-token"} end)

    Mimic.stub(Glossia.Github.Client, :get_pull_request, fn "glossia/demo", 8, "github-token" ->
      {:ok, %{"state" => "open"}}
    end)

    Mimic.stub(Glossia.Github.Client, :get_commit, fn "glossia/demo",
                                                      parent_sha,
                                                      "github-token" ->
      {:ok, %{"tree" => %{"sha" => "tree-for-#{parent_sha}"}}}
    end)

    Mimic.stub(Glossia.Github.Client, :create_blob, fn "glossia/demo", _params, "github-token" ->
      {:ok, %{"sha" => "blob-sha"}}
    end)

    Mimic.stub(Glossia.Github.Client, :create_tree, fn "glossia/demo", params, "github-token" ->
      send(test_pid, {:tree, params})
      {:ok, %{"sha" => "commit-tree-#{length(params.tree)}"}}
    end)

    Mimic.stub(Glossia.Github.Client, :create_commit, fn "glossia/demo", params, "github-token" ->
      send(test_pid, {:commit, params})

      case params.parents do
        ["abc1234567890"] -> {:ok, %{"sha" => "first-translation-commit"}}
        ["first-translation-commit"] -> {:ok, %{"sha" => "second-translation-commit"}}
      end
    end)

    Mimic.stub(Glossia.Github.Client, :create_branch, fn "glossia/demo",
                                                         branch,
                                                         sha,
                                                         "github-token" ->
      send(test_pid, {:created_branch, branch, sha})
      {:ok, %{}}
    end)

    Mimic.stub(Glossia.Github.Client, :update_ref, fn "glossia/demo",
                                                      branch,
                                                      sha,
                                                      "github-token" ->
      send(test_pid, {:updated_branch, branch, sha})
      {:ok, %{}}
    end)

    Mimic.stub(Glossia.Github.Client, :create_pull_request, fn "glossia/demo",
                                                               _params,
                                                               "github-token" ->
      {:ok, %{"html_url" => "https://github.com/glossia/demo/pull/8", "number" => 8}}
    end)

    assert :ok = Translate.run(session.id)

    assert_received {:tree, %{tree: first_entries}}
    assert length(first_entries) == 2
    assert_received {:tree, %{tree: second_entries}}
    assert length(second_entries) == 2
    assert_received {:commit, %{parents: ["abc1234567890"]}}
    assert_received {:commit, %{parents: ["first-translation-commit"]}}

    assert_received {
      :created_branch,
      "glossia/translate-abc123456789",
      "first-translation-commit"
    }

    assert_received {
      :updated_branch,
      "heads/glossia/translate-abc123456789",
      "second-translation-commit"
    }

    updated = Repo.get!(TranslationSession, session.id)
    assert updated.status == "completed"
    assert updated.publication_commit_sha == "second-translation-commit"
    assert updated.pull_request_url == "https://github.com/glossia/demo/pull/8"
    assert updated.pull_request_number == 8
  end

  test "starts a new pull request after a checkpoint is merged" do
    {user, project} = project_with_installation("merged-checkpoint@test.com", "merged-checkpoint")
    session = session_for(user, project)
    test_pid = self()

    {:ok, session} =
      TranslationSessions.update_session_publication(session, %{
        publication_branch: "glossia/translate-abc123456789",
        publication_commit_sha: "first-translation-commit",
        pull_request_url: "https://github.com/glossia/demo/pull/8",
        pull_request_number: 8
      })

    Mimic.stub(Glossia.Github.App, :installation_token, fn 42 -> {:ok, "github-token"} end)

    Mimic.stub(Glossia.Github.Client, :get_pull_request, fn "glossia/demo", 8, "github-token" ->
      {:ok, %{"state" => "closed", "merged_at" => "2026-08-29T12:00:00Z"}}
    end)

    Mimic.stub(Glossia.Github.Client, :get_ref, fn "glossia/demo", "heads/main", "github-token" ->
      {:ok, %{"object" => %{"sha" => "merged-default-branch"}}}
    end)

    Mimic.stub(Glossia.Github.Client, :get_commit, fn "glossia/demo",
                                                      "merged-default-branch",
                                                      "github-token" ->
      {:ok, %{"tree" => %{"sha" => "merged-default-tree"}}}
    end)

    Mimic.stub(Glossia.Github.Client, :create_blob, fn "glossia/demo", _params, "github-token" ->
      {:ok, %{"sha" => "blob-sha"}}
    end)

    Mimic.stub(Glossia.Github.Client, :create_tree, fn "glossia/demo", params, "github-token" ->
      send(test_pid, {:tree, params})
      {:ok, %{"sha" => "new-tree"}}
    end)

    Mimic.stub(Glossia.Github.Client, :create_commit, fn "glossia/demo", params, "github-token" ->
      send(test_pid, {:commit, params})
      {:ok, %{"sha" => "second-translation-commit"}}
    end)

    Mimic.stub(Glossia.Github.Client, :create_branch, fn "glossia/demo",
                                                         branch,
                                                         sha,
                                                         "github-token" ->
      send(test_pid, {:created_branch, branch, sha})
      {:ok, %{}}
    end)

    Mimic.stub(Glossia.Github.Client, :create_pull_request, fn "glossia/demo",
                                                               _params,
                                                               "github-token" ->
      {:ok, %{"html_url" => "https://github.com/glossia/demo/pull/9", "number" => 9}}
    end)

    changes = [
      %{path: "docs/i18n/es/reference.md", status: "added", content: "# Referencia\n"},
      %{path: ".glossia/docs/reference.md/es.lock", status: "added", content: "{}"}
    ]

    assert {:ok, publication} =
             Translate.publish_changes(%{session_id: session.id}, %{changes: changes})

    assert_received {:tree, %{base_tree: "merged-default-tree", tree: entries}}
    assert length(entries) == 2
    assert_received {:commit, %{parents: ["merged-default-branch"]}}
    assert_received {:created_branch, branch, "second-translation-commit"}
    assert branch =~ ~r/^glossia\/translate-abc123456789-[a-f0-9]{8}$/
    assert publication.ref == branch
    assert publication.pull_request_url == "https://github.com/glossia/demo/pull/9"

    updated = Repo.get!(TranslationSession, session.id)
    assert updated.publication_branch == branch
    assert updated.publication_commit_sha == "second-translation-commit"
    assert updated.pull_request_number == 9
  end

  test "does not run a cancelled translation session" do
    {user, project} =
      project_with_installation("cancelled-translate@test.com", "cancelled-translate")

    session = session_for(user, project)
    {:ok, session} = TranslationSessions.update_session_status(session, "cancelled")

    Mimic.reject(&Glossia.Translations.RepositoryRun.run/5)

    assert :ok = Translate.run(session.id)
  end

  test "does not mint another token when no files changed" do
    {user, project} =
      project_with_installation("translate-token-age@test.com", "translate-token-age")

    session = session_for(user, project)

    # A run can outlive the hour GitHub gives an installation token. Freezing
    # one at the start meant a long run presented a dead credential on its
    # first write, so the token must be resolved at publication time.
    {:ok, minted} = Elixir.Agent.start_link(fn -> 0 end)

    Mimic.stub(Glossia.Github.App, :installation_token, fn 42 ->
      count = Elixir.Agent.get_and_update(minted, &{&1 + 1, &1 + 1})
      {:ok, "github-token-#{count}"}
    end)

    stub_run([])

    Mimic.stub(Glossia.Translations.RepositoryRun, :run, fn _session,
                                                            _account,
                                                            _repository,
                                                            _locales,
                                                            opts ->
      assert is_function(opts[:after_item_completed], 1)

      {:ok, []}
    end)

    assert :ok = Translate.run(session.id)
    assert 1 == Elixir.Agent.get(minted, & &1)
  end

  test "mints a new token and retries when GitHub rejects the one it had" do
    {user, project} =
      project_with_installation("translate-token-401@test.com", "translate-token-401")

    session = session_for(user, project)

    {:ok, tokens} = Elixir.Agent.start_link(fn -> [] end)

    Mimic.stub(Glossia.Github.App, :installation_token, fn 42 ->
      count = length(Elixir.Agent.get(tokens, & &1))
      {:ok, "github-token-#{count}"}
    end)

    # The first token is rejected, standing in for one that expired between the
    # cache handing it over and the request landing. Giving up here would throw
    # away every translation the run has produced.
    Mimic.stub(Glossia.Github.Client, :get_commit, fn "glossia/demo", _sha, token ->
      Elixir.Agent.update(tokens, &(&1 ++ [token]))

      case token do
        "github-token-0" ->
          {:error, {:api_error, 401, %{"message" => "Bad credentials", "status" => "401"}}}

        _ ->
          {:ok, %{"tree" => %{"sha" => "base-tree-sha"}}}
      end
    end)

    Mimic.stub(Glossia.Github.Client, :create_blob, fn "glossia/demo", _params, _token ->
      {:ok, %{"sha" => "blob-sha"}}
    end)

    Mimic.stub(Glossia.Github.Client, :create_tree, fn "glossia/demo", _params, _token ->
      {:ok, %{"sha" => "tree-sha"}}
    end)

    Mimic.stub(Glossia.Github.Client, :create_commit, fn "glossia/demo", _params, _token ->
      {:ok, %{"sha" => "commit-sha"}}
    end)

    Mimic.stub(Glossia.Github.Client, :create_branch, fn "glossia/demo", _branch, _sha, _token ->
      {:ok, %{}}
    end)

    Mimic.stub(Glossia.Github.Client, :create_pull_request, fn "glossia/demo", _params, _token ->
      {:ok, %{"html_url" => "https://github.com/glossia/demo/pull/7"}}
    end)

    stub_run([
      %{path: "docs/i18n/es/guide.md", status: "added", content: "# Hola\n"}
    ])

    assert :ok = Translate.run(session.id)

    # Rejected once, then retried with a freshly minted token.
    assert ["github-token-0", "github-token-1"] = Elixir.Agent.get(tokens, & &1)

    updated = Repo.get!(TranslationSession, session.id)
    assert updated.status == "completed"
    assert updated.pull_request_url == "https://github.com/glossia/demo/pull/7"
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

  test "fails the session when a translation item fails" do
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

    assert {:error, {:translation_items_failed, [_failure]}} = Translate.run(session.id)

    updated = Repo.get!(TranslationSession, session.id)
    assert updated.status == "failed"

    assert updated.error == "Translation failed for 1 file. Review the file errors and retry."

    assert updated.completed_at
  end

  test "records safe item diagnostics when a translation item fails" do
    {user, project} =
      project_with_installation("translate-diagnostics@test.com", "translate-diagnostics")

    session = session_for(user, project)

    Mimic.stub(Glossia.Github.App, :installation_token, fn 42 -> {:ok, "github-token"} end)

    Mimic.stub(Glossia.Translations.RepositoryRun, :run, fn _session,
                                                            _account,
                                                            _repository,
                                                            _locales,
                                                            _opts ->
      {:error,
       {:translation_items_failed,
        [
          %{
            index: 7,
            output_path: "app/priv/i18n/ja/blog/why-glossia.md",
            locale: "ja",
            reason: %{
              kind: "validation-empty-output",
              scope: "item",
              raw: "private source content"
            },
            diagnostics: %{
              source_path: "app/priv/blog/why-glossia.md",
              format: "markdown",
              frontmatter_mode: :translate,
              model: "openai/gpt-5",
              provider: "openai"
            }
          }
        ]}}
    end)

    log =
      capture_log(fn ->
        assert {:error, {:translation_items_failed, [_failure]}} = Translate.run(session.id)
      end)

    assert log =~ "Translation session failed"
    assert log =~ ~s("translation_session_id":"#{session.id}")
    assert log =~ ~s("source_path":"app/priv/blog/why-glossia.md")
    assert log =~ ~s("output_path":"app/priv/i18n/ja/blog/why-glossia.md")
    assert log =~ ~s("failure_kind":"validation-empty-output")
    refute log =~ "private source content"
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
