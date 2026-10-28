defmodule Glossia.TranslationSessions.TranslateTest do
  use Glossia.DataCase, async: true
  use GlossiaWeb, :verified_routes
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
  # in a FLAME runner) and its change list feeds the existing GitHub pull
  # request builder. These tests stub RepositoryRun.run/5 and exercise the
  # publication and outcome path.

  # The pull request description is refreshed whenever a run publishes or
  # ends. Tests that care assert on it; the rest must never reach GitHub.
  setup do
    # Real local synchronization and Git object/ref storage are covered by
    # PublicationIntegrationTest. These tests isolate API errors and outcomes.
    stub(Glossia.Translations.Repository, :prepare_publication, fn repository, changes ->
      {:ok,
       %{changes: changes, parents: [repository.publication_commit_sha || repository.commit_sha]}}
    end)

    stub(Glossia.Github.Client, :get_ref, fn _, "heads/" <> branch, _ ->
      session =
        Repo.one(
          from(s in TranslationSession,
            where: s.publication_branch == ^branch,
            order_by: [desc: s.inserted_at],
            limit: 1
          )
        )

      if session && session.publication_commit_sha,
        do: {:ok, %{"object" => %{"sha" => session.publication_commit_sha}}},
        else: {:error, {:api_error, 404, %{}}}
    end)

    stub(Glossia.Github.Client, :get_pull_request, fn _, _, _ ->
      {:ok, %{"state" => "open"}}
    end)

    Mimic.stub(Glossia.Github.Client, :list_pull_requests, fn _repository, _token, _opts ->
      {:ok, []}
    end)

    Mimic.stub(Glossia.Github.Client, :update_pull_request, fn _repository,
                                                               _number,
                                                               _params,
                                                               _token ->
      {:ok, %{}}
    end)

    :ok
  end

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

  defp stub_run(changes, notify \\ nil) do
    Mimic.stub(Glossia.Translations.RepositoryRun, :run, fn _session,
                                                            _account,
                                                            _repository,
                                                            _locales,
                                                            opts ->
      if notify, do: send(notify, {:repository_run_opts, opts})
      {:ok, changes}
    end)
  end

  test "a run needing linguistic input waits without failing or restarting its runner" do
    {user, project} = project_with_installation("translate-review@test.com", "translate-review")
    session = session_for(user, project)
    stub(Glossia.Github.App, :installation_token, fn 42 -> {:ok, "github-token"} end)

    stub(Glossia.Translations.RepositoryRun, :run, fn started, _, _, _, _ ->
      assert {:ok, _} =
               Glossia.LinguisticReviews.request(
                 started.id,
                 %{
                   source_path: "guide.txt",
                   output_path: "es/guide.txt",
                   locale: "es",
                   context_targets: %{}
                 },
                 String.duplicate("a", 64),
                 %{
                   reason: "missing_context",
                   question: "What does branch mean?",
                   source: "Create a branch.",
                   translation: "Crea una rama."
                 }
               )

      {:awaiting_input, []}
    end)

    assert {:ok, %{status: "awaiting_input", error: nil, completed_at: nil}} =
             Translate.run(session.id)

    assert Glossia.LinguisticReviews.open_for_session?(session.id)
    assert :ok = Translate.run(session.id)
    assert Repo.get!(TranslationSession, session.id).status == "awaiting_input"
  end

  test "exhausted rate limits enqueue an automatic continuation through the launcher" do
    {user, project} =
      project_with_installation("translate-throttle@test.com", "translate-throttle")

    session = session_for(user, project)
    stub(Glossia.Github.App, :installation_token, fn 42 -> {:ok, "github-token"} end)

    stub(Glossia.Translations.RepositoryRun, :run, fn _, _, _, _, _ ->
      {:error,
       {:translation_items_failed,
        [
          %{
            output_path: "es.po",
            reason: %{kind: "provider-rate-limit", scope: "session", status: 429}
          }
        ]}}
    end)

    Oban.Testing.with_testing_mode(:manual, fn ->
      capture_log(fn ->
        assert {:error, {:translation_items_failed, _}} = Translate.run(session.id)
      end)

      continuation =
        Repo.one!(
          from(s in TranslationSession, where: s.continued_from_session_id == ^session.id)
        )

      assert continuation.status == "pending"
      assert continuation.provider_retry_count == 1
    end)
  end

  test "opens one pull request after the full translated change list is ready" do
    {user, project} = project_with_installation("translate@test.com", "translate")
    session = session_for(user, project)
    test_pid = self()

    stub_run(
      [
        %{path: "docs/i18n/es/guide.md", status: "added", content: "# Hola mundo\n"},
        %{path: ".glossia/docs/guide.md/es.lock", status: "added", content: "{}"},
        %{path: "docs/i18n/es/reference.md", status: "added", content: "# Referencia\n"},
        %{path: ".glossia/docs/reference.md/es.lock", status: "added", content: "{}"}
      ],
      test_pid
    )

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

    assert_received {:repository_run_opts, run_opts}
    assert is_function(Keyword.fetch!(run_opts, :after_item_completed), 1)
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
    assert updated.summary == "Updated translation pull request."
    assert updated.publication_branch == "glossia/translate-abc123456789"
    assert updated.publication_commit_sha == "translation-commit-sha"
    assert updated.pull_request_url == "https://github.com/glossia/demo/pull/2"
  end

  test "publishes completed files together in one commit on one pull request" do
    {user, project} = project_with_installation("checkpoint-translate@test.com", "checkpoint")
    session = session_for(user, project)
    test_pid = self()

    first_changes = [
      %{path: "docs/i18n/es/guide.md", status: "added", content: "# Hola mundo\n"},
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
      callback = Keyword.fetch!(opts, :after_item_completed)

      assert :ok = callback.(first_changes)
      assert :ok = callback.(second_changes)

      {:ok, first_changes ++ second_changes}
    end)

    Mimic.stub(Glossia.Github.App, :installation_token, fn 42 -> {:ok, "github-token"} end)

    Mimic.expect(Glossia.Github.Client, :get_commit, fn "glossia/demo",
                                                        "abc1234567890",
                                                        "github-token" ->
      {:ok, %{"tree" => %{"sha" => "source-tree-sha"}}}
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
                                                           base_tree: "source-tree-sha",
                                                           tree: entries
                                                         },
                                                         "github-token" ->
      send(test_pid, {:batch_tree, entries})
      {:ok, %{"sha" => "batch-tree-sha"}}
    end)

    Mimic.expect(Glossia.Github.Client, :create_commit, fn "glossia/demo",
                                                           %{parents: ["abc1234567890"]},
                                                           "github-token" ->
      {:ok, %{"sha" => "batch-commit"}}
    end)

    Mimic.expect(Glossia.Github.Client, :create_branch, fn "glossia/demo",
                                                           "glossia/translate-abc123456789",
                                                           "batch-commit",
                                                           "github-token" ->
      {:ok, %{}}
    end)

    Mimic.expect(Glossia.Github.Client, :create_pull_request, fn "glossia/demo",
                                                                 params,
                                                                 "github-token" ->
      assert params.head == "glossia/translate-abc123456789"
      {:ok, %{"html_url" => "https://github.com/glossia/demo/pull/3", "number" => 3}}
    end)

    assert :ok = Translate.run(session.id)

    assert_received {:batch_tree, entries}

    assert Enum.map(entries, & &1.path) ==
             Enum.sort(Enum.map(first_changes ++ second_changes, & &1.path))

    updated = Repo.get!(TranslationSession, session.id)
    assert updated.status == "completed"
    assert updated.publication_branch == "glossia/translate-abc123456789"
    assert updated.publication_commit_sha == "batch-commit"
    assert updated.pull_request_number == 3
    assert updated.pull_request_url == "https://github.com/glossia/demo/pull/3"
  end

  test "describes translation work and keeps it current without a running web endpoint" do
    {user, project} = project_with_installation("summary-translate@test.com", "summary")
    session = session_for(user, project)
    test_pid = self()
    base_uri = URI.parse(GlossiaWeb.Endpoint.url())

    # Detached translation Jobs have no endpoint supervisor or warmed URL/path
    # state. Reject both helpers so the normal web test tree cannot hide that.
    Mimic.reject(&GlossiaWeb.Endpoint.url/0)
    Mimic.reject(&GlossiaWeb.Endpoint.path/1)

    changes = [
      %{path: "docs/i18n/es/guide.md", status: "added", content: "# Hola mundo\n"},
      %{path: ".glossia/docs/guide.md/es.lock", status: "added", content: "{}"}
    ]

    Mimic.stub(Glossia.Translations.RepositoryRun, :run, fn running,
                                                            _account,
                                                            _repo,
                                                            _locales,
                                                            opts ->
      for event <- [
            %{type: "plan_assessed", seq: 2, total: 3, needs_translation: 1, up_to_date: 2},
            %{
              type: "item_started",
              seq: 3,
              index: 0,
              output_path: "docs/i18n/es/guide.md",
              locale: "es"
            },
            %{
              type: "item_completed",
              seq: 4,
              index: 0,
              output_path: "docs/i18n/es/guide.md",
              model_calls: 2,
              glossary_applied: [%{id: "account:tuist", term: "Tuist", translation: "Tuist"}],
              quality: %{passed: true, threshold: 7, ratings: [%{label: "Accuracy", score: 9}]}
            }
          ] do
        TranslationSessions.broadcast_session_event(running, event)
      end

      assert :ok = Keyword.fetch!(opts, :after_item_completed).(changes)
      {:ok, changes}
    end)

    Mimic.stub(Glossia.Github.App, :installation_token, fn 42 -> {:ok, "github-token"} end)

    Mimic.stub(Glossia.Github.Client, :get_commit, fn _repo, _sha, _token ->
      {:ok, %{"tree" => %{"sha" => "tree"}}}
    end)

    Mimic.stub(Glossia.Github.Client, :create_blob, fn _repo, _params, _token ->
      {:ok, %{"sha" => "blob"}}
    end)

    Mimic.stub(Glossia.Github.Client, :create_tree, fn _repo, _params, _token ->
      {:ok, %{"sha" => "tree"}}
    end)

    Mimic.stub(Glossia.Github.Client, :create_commit, fn _repo, _params, _token ->
      {:ok, %{"sha" => "commit"}}
    end)

    Mimic.stub(Glossia.Github.Client, :create_branch, fn _repo, _branch, _sha, _token ->
      {:ok, %{}}
    end)

    Mimic.expect(Glossia.Github.Client, :create_pull_request, fn "glossia/demo",
                                                                 params,
                                                                 "github-token" ->
      send(test_pid, {:created, params.body})
      {:ok, %{"html_url" => "https://github.com/glossia/demo/pull/9", "number" => 9}}
    end)

    Mimic.expect(Glossia.Github.Client, :update_pull_request, fn "glossia/demo",
                                                                 9,
                                                                 %{body: body},
                                                                 "github-token" ->
      send(test_pid, {:updated, body})
      {:ok, %{}}
    end)

    assert :ok = Translate.run(session.id)

    assert_received {:created, created}
    assert created =~ "## Summary"
    assert created =~ "🔄 **Translating `abc1234`.**"

    assert_received {:updated, body}

    assert body =~
             "Glossia translated **1 file** into **1 language** from **1 source commit** on `main`."

    assert body =~ "✅ **Up to date with `abc1234`.** 2 files were already up to date."
    assert body =~ "| `es` | 1 | 0 | 2 | 9.0/10 |"
    assert body =~ "[`abc1234`](https://github.com/glossia/demo/commit/abc1234567890)"

    assert body =~
             "[`docs/i18n/es/guide.md`](https://github.com/glossia/demo/blob/glossia/translate-abc123456789/docs/i18n/es/guide.md)"

    assert body =~ "| Tuist | Tuist | 1 |"
    assert body =~ "## Reviewing this pull request"

    assert body =~
             url(base_uri, ~p"/#{user.account.handle}/#{project.handle}/-/sessions/#{session.id}")

    assert body =~
             url(base_uri, ~p"/#{user.account.handle}/#{project.handle}/-/translations")
  end

  for recorded? <- [true, false] do
    @publication_recorded recorded?

    test "reuses an existing PR when its publication metadata is recorded: #{recorded?}" do
      {user, project} = project_with_installation("reused-translate@test.com", "reused")
      session = session_for(user, project)

      session =
        if @publication_recorded do
          {:ok, session} =
            TranslationSessions.update_session_publication(session, %{
              publication_branch: "glossia/translate-abc123456789",
              publication_commit_sha: "translation-commit-sha",
              pull_request_url: "https://github.com/glossia/demo/pull/2",
              pull_request_number: 2
            })

          session
        else
          expect(Glossia.Github.Client, :list_pull_requests, 2, fn "glossia/demo",
                                                                   "github-token",
                                                                   opts ->
            assert opts[:base] == "main"

            if opts[:page] == 1 do
              {:ok, List.duplicate(%{"user" => %{"login" => "someone-else"}}, 100)}
            else
              assert opts[:page] == 2

              {:ok,
               [
                 %{"user" => %{"login" => "someone-else"}, "head" => %{"ref" => "feature"}},
                 %{
                   "user" => %{"login" => "glossia[bot]"},
                   "head" => %{
                     "ref" => "glossia/translate-abc123456789",
                     "sha" => "translation-commit-sha",
                     "repo" => %{"full_name" => "glossia/demo"}
                   },
                   "html_url" => "https://github.com/glossia/demo/pull/2",
                   "number" => 2
                 }
               ]}
            end
          end)

          session
        end

      Mimic.stub(Glossia.Github.App, :installation_token, fn 42 -> {:ok, "github-token"} end)

      expect(Glossia.Github.Client, :get_ref, fn _, "heads/glossia/translate-abc123456789", _ ->
        {:ok, %{"object" => %{"sha" => "translation-commit-sha"}}}
      end)

      Mimic.expect(Glossia.Github.Client, :get_commit, fn "glossia/demo",
                                                          "translation-commit-sha",
                                                          "github-token" ->
        {:ok, %{"tree" => %{"sha" => "previous-tree-sha"}}}
      end)

      Mimic.expect(Glossia.Github.Client, :create_blob, fn "glossia/demo",
                                                           %{
                                                             content: _content,
                                                             encoding: "base64"
                                                           },
                                                           "github-token" ->
        {:ok, %{"sha" => "blob-sha"}}
      end)

      Mimic.expect(Glossia.Github.Client, :create_tree, fn "glossia/demo",
                                                           %{base_tree: "previous-tree-sha"},
                                                           "github-token" ->
        {:ok, %{"sha" => "updated-tree-sha"}}
      end)

      Mimic.expect(Glossia.Github.Client, :create_commit, fn "glossia/demo",
                                                             %{
                                                               parents: ["translation-commit-sha"]
                                                             },
                                                             "github-token" ->
        {:ok, %{"sha" => "updated-translation-commit-sha"}}
      end)

      Mimic.expect(Glossia.Github.Client, :update_ref, fn "glossia/demo",
                                                          "heads/glossia/translate-abc123456789",
                                                          "updated-translation-commit-sha",
                                                          "github-token" ->
        {:ok, %{}}
      end)

      Mimic.reject(&Glossia.Github.Client.create_pull_request/3)

      assert {:ok, publication} =
               Translate.publish_changes(
                 %{session_id: session.id},
                 %{
                   changes: [
                     %{path: "docs/i18n/es/guide.md", status: "added", content: "# Hola\n"}
                   ]
                 }
               )

      assert publication.ref == "glossia/translate-abc123456789"
      assert publication.pull_request_url == "https://github.com/glossia/demo/pull/2"

      updated = Repo.get!(TranslationSession, session.id)
      assert updated.publication_commit_sha == "updated-translation-commit-sha"
      assert updated.pull_request_number == 2
    end
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
      assert is_function(Keyword.fetch!(opts, :after_item_completed), 1)

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
    assert updated.outcome == "content_hit"
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
    assert updated.outcome == "failed"
    assert updated.error == Glossia.TranslationSessions.Error.describe({:clone_failed, "boom"})
    refute updated.error =~ "boom"
  end

  test "stores an actionable planning failure instead of an inspected tuple" do
    {user, project} = project_with_installation("translate-plan@test.com", "translate-plan")
    session = session_for(user, project)

    reason =
      {:planning_failed, "sources must be a mapping of source patterns to target path templates"}

    Mimic.stub(Glossia.Github.App, :installation_token, fn 42 -> {:ok, "github-token"} end)

    Mimic.stub(Glossia.Translations.RepositoryRun, :run, fn _, _, _, _, _ ->
      {:error, reason}
    end)

    assert {:error, ^reason} = Translate.run(session.id)

    updated = Repo.get!(TranslationSession, session.id)
    assert updated.status == "failed"
    assert updated.error == Glossia.TranslationSessions.Error.describe(reason)
    refute updated.error =~ "planning_failed"
  end

  test "passes an existing publication branch to a resumed repository run" do
    {user, project} = project_with_installation("translate-resume@test.com", "translate-resume")
    session = session_for(user, project)

    {:ok, session} =
      TranslationSessions.update_session_publication(session, %{
        publication_branch: "glossia/translate-abc123456789",
        publication_commit_sha: "checkpoint-commit",
        pull_request_url: "https://github.com/glossia/demo/pull/2",
        pull_request_number: 2
      })

    Mimic.stub(Glossia.Github.App, :installation_token, fn 42 -> {:ok, "github-token"} end)

    Mimic.stub(Glossia.Translations.RepositoryRun, :run, fn _session,
                                                            _account,
                                                            repository,
                                                            _locales,
                                                            _opts ->
      send(self(), {:repository, repository})
      {:error, {:clone_failed, "boom"}}
    end)

    assert {:error, {:clone_failed, "boom"}} = Translate.run(session.id)

    assert_received {:repository, %{publication_branch: "glossia/translate-abc123456789"}}
  end

  test "does not advance a continued translation branch when assessment finds no changes" do
    {user, project} =
      project_with_installation("translate-continuation@test.com", "translate-continuation")

    previous_session = session_for(user, project)

    {:ok, session} =
      TranslationSessions.create_session(user.account, project, %{
        commit_sha: "def9876543210",
        commit_message: "Update guide",
        source_language: "en",
        target_languages: ["es"],
        continued_from_session_id: previous_session.id,
        publication_branch: "glossia/translate-abc123456789",
        publication_commit_sha: "checkpoint-commit",
        pull_request_url: "https://github.com/glossia/demo/pull/2",
        pull_request_number: 2
      })

    Mimic.stub(Glossia.Github.App, :installation_token, fn 42 -> {:ok, "github-token"} end)

    Mimic.expect(Glossia.Github.Client, :get_pull_request, fn "glossia/demo", 2, "github-token" ->
      {:ok, %{"state" => "open"}}
    end)

    Mimic.expect(Glossia.Github.Client, :compare_commits, fn "glossia/demo",
                                                             "abc1234567890",
                                                             "def9876543210",
                                                             "github-token" ->
      {:ok, %{"status" => "ahead"}}
    end)

    Mimic.reject(&Glossia.Github.Client.merge_branch/3)
    Mimic.reject(&Glossia.Github.Client.update_ref/4)

    Mimic.stub(Glossia.Translations.RepositoryRun, :run, fn _session,
                                                            _account,
                                                            repository,
                                                            _locales,
                                                            _opts ->
      send(self(), {:continued_repository, repository})
      {:ok, []}
    end)

    assert :ok = Translate.run(session.id)

    assert_received {:continued_repository,
                     %{
                       commit_sha: "def9876543210",
                       publication_branch: "glossia/translate-abc123456789"
                     }}

    updated = Repo.get!(TranslationSession, session.id)
    assert updated.publication_commit_sha == "checkpoint-commit"
    assert updated.status == "completed"
  end

  test "preserves the publication and fails when the default branch history was rewritten" do
    {user, project} =
      project_with_installation("translate-diverged@test.com", "translate-diverged")

    previous_session = session_for(user, project)

    {:ok, session} =
      TranslationSessions.create_session(user.account, project, %{
        commit_sha: "rewritten-source",
        source_language: "en",
        target_languages: ["es"],
        continued_from_session_id: previous_session.id,
        publication_branch: "glossia/translate-abc123456789",
        publication_commit_sha: "checkpoint-commit"
      })

    Mimic.stub(Glossia.Github.App, :installation_token, fn 42 -> {:ok, "github-token"} end)

    Mimic.expect(Glossia.Github.Client, :compare_commits, fn "glossia/demo",
                                                             "abc1234567890",
                                                             "rewritten-source",
                                                             "github-token" ->
      {:ok, %{"status" => "diverged"}}
    end)

    Mimic.reject(&Glossia.Github.Client.merge_branch/3)

    Mimic.reject(&Glossia.Translations.RepositoryRun.run/5)
    Mimic.reject(&Glossia.Github.Client.create_pull_request/3)

    assert {:error, :translation_source_history_changed} = Translate.run(session.id)

    updated = Repo.get!(TranslationSession, session.id)
    assert updated.publication_branch == "glossia/translate-abc123456789"
    assert updated.publication_commit_sha == "checkpoint-commit"
    assert updated.status == "failed"
  end

  test "an open PR with a merge conflict is not replaced by a second PR" do
    {user, project} =
      project_with_installation("translate-conflict@test.com", "translate-conflict")

    previous_session = session_for(user, project)

    {:ok, session} =
      TranslationSessions.create_session(user.account, project, %{
        commit_sha: "next-source",
        source_language: "en",
        target_languages: ["es"],
        continued_from_session_id: previous_session.id,
        publication_branch: "glossia/translate-abc123456789",
        publication_commit_sha: "checkpoint-commit",
        pull_request_url: "https://github.com/glossia/demo/pull/2",
        pull_request_number: 2
      })

    stub(Glossia.Github.App, :installation_token, fn 42 -> {:ok, "github-token"} end)

    stub(Glossia.Github.Client, :get_pull_request, fn _, 2, _ ->
      {:ok, %{"state" => "open"}}
    end)

    stub(Glossia.Github.Client, :compare_commits, fn _, _, _, _ ->
      {:ok, %{"status" => "ahead"}}
    end)

    expect(Glossia.Translations.RepositoryRun, :run, fn _, _, _, _, _ ->
      {:error, :translation_branch_conflict}
    end)

    reject(&Glossia.Github.Client.create_pull_request/3)
    reject(&Glossia.Github.Client.merge_branch/3)

    log =
      capture_log(fn ->
        assert {:error, :translation_branch_conflict} = Translate.run(session.id)
      end)

    updated = Repo.get!(TranslationSession, session.id)
    assert updated.pull_request_number == 2
    assert updated.publication_branch == session.publication_branch
    assert updated.publication_commit_sha == "checkpoint-commit"
    assert updated.status == "failed"
    assert updated.failure_kind == "translation_branch_conflict"
    assert updated.error =~ "pull request branch conflicts"
    assert updated.error =~ "Resolve the conflicts in the existing pull request, then retry."
    refute updated.error =~ "private-output"
    assert log =~ ~s("failure_kind":"translation_branch_conflict")
    refute log =~ "private-output"

    [event] = Glossia.Ingestion.list_translation_session_events(session.id)
    assert JSON.decode!(event.metadata)["failure_kind"] == "translation_branch_conflict"
    assert event.content == updated.error
  end

  test "publication defers before any GitHub calls when the shared budget is exhausted" do
    {user, project} =
      project_with_installation("translate-paced@test.com", "translate-paced")

    session = session_for(user, project)

    project
    |> Ecto.Changeset.change(translation_last_pushed_at: DateTime.add(DateTime.utc_now(), 60))
    |> Repo.update!()

    reject(&Glossia.Github.App.installation_token/1)
    reject(&Glossia.Github.Client.create_branch/4)
    reject(&Glossia.Github.Client.update_ref/4)
    reject(&Glossia.Github.Client.create_pull_request/3)

    assert {:wait, ms} =
             Translate.publish_changes(
               %{session_id: session.id},
               %{changes: [%{path: "es.md", status: "added", content: "Hola"}]},
               wait: false
             )

    assert ms > 0
    assert is_nil(Repo.get!(TranslationSession, session.id).publication_branch)

    {:ok, _} = TranslationSessions.update_session_status(session, "cancelled")

    assert {:error, :translation_cancelled} =
             Translate.publish_changes(
               %{session_id: session.id},
               %{changes: [%{path: "es.md", status: "added", content: "Hola"}]},
               wait: false
             )
  end

  for {outcome, response} <- [
        {"merged", %{"state" => "closed", "merged" => true}},
        {"closed without merging", %{"state" => "closed", "merged" => false}}
      ] do
    @pull_request_response response

    test "starts fresh after the inherited pull request was #{outcome}" do
      {user, project} =
        project_with_installation("translate-closed-pr@test.com", "translate-closed-pr")

      previous_session = session_for(user, project)

      {:ok, session} =
        TranslationSessions.create_session(user.account, project, %{
          commit_sha: "def9876543210",
          source_language: "en",
          target_languages: ["es"],
          continued_from_session_id: previous_session.id,
          publication_branch: "glossia/translate-abc123456789",
          publication_commit_sha: "checkpoint-commit",
          pull_request_url: "https://github.com/glossia/demo/pull/2",
          pull_request_number: 2
        })

      Mimic.stub(Glossia.Github.App, :installation_token, fn 42 -> {:ok, "github-token"} end)

      Mimic.expect(Glossia.Github.Client, :get_pull_request, fn "glossia/demo",
                                                                2,
                                                                "github-token" ->
        {:ok, @pull_request_response}
      end)

      Mimic.reject(&Glossia.Github.Client.compare_commits/4)
      Mimic.reject(&Glossia.Github.Client.merge_branch/3)

      Mimic.stub(Glossia.Translations.RepositoryRun, :run, fn _session,
                                                              _account,
                                                              repository,
                                                              _locales,
                                                              _opts ->
        send(self(), {:merged_pull_request_repository, repository})
        {:ok, []}
      end)

      assert :ok = Translate.run(session.id)
      assert_received {:merged_pull_request_repository, %{publication_branch: nil}}

      updated = Repo.get!(TranslationSession, session.id)
      assert is_nil(updated.pull_request_url)
      assert is_nil(updated.pull_request_number)
      assert String.starts_with?(updated.publication_branch, "glossia/translate-def987654321-")
      assert is_nil(updated.publication_commit_sha)
    end
  end

  test "a cancelled runner cannot overwrite cancellation with a failure" do
    {user, project} =
      project_with_installation("translate-cancel-race@test.com", "translate-cancel-race")

    session = session_for(user, project)

    Mimic.stub(Glossia.Github.App, :installation_token, fn 42 -> {:ok, "github-token"} end)

    Mimic.stub(Glossia.Translations.RepositoryRun, :run, fn running_session,
                                                            _account,
                                                            _repository,
                                                            _locales,
                                                            opts ->
      {:ok, _cancelled} =
        TranslationSessions.update_session_status(running_session, "cancelled")

      callback = Keyword.fetch!(opts, :after_item_completed)

      # The file is only batched here; publishing it at the end of the run
      # finds the session cancelled and drops it.
      assert :ok =
               callback.([
                 %{path: "docs/i18n/es/guide.md", status: "added", content: "# Hola\n"}
               ])

      {:error,
       {:translation_items_failed,
        [%{output_path: "docs/i18n/es/guide.md", reason: %{kind: "provider-timeout"}}]}}
    end)

    assert :ok = Translate.run(session.id)
    assert Repo.get!(TranslationSession, session.id).status == "cancelled"

    refute Repo.exists?(
             from s in TranslationSession, where: s.continued_from_session_id == ^session.id
           )
  end

  for {name, reason, retryable} <- [
        {"rate limit", %{kind: "provider-rate-limit", status: 429}, true},
        {"504", %{kind: "provider-error", status: 504}, true},
        {"timeout", {:llm_failed, :timeout}, true},
        {"transport failure", {:llm_failed, %Req.TransportError{reason: :closed}}, true},
        {"credentials", %{kind: "provider-credentials", status: 401}, false},
        {"credit", %{kind: "provider-credit", status: 402}, false},
        {"client error", %{kind: "provider-error", status: 400}, false},
        {"validation", %{kind: "validation-structure"}, false}
      ] do
    @provider_reason reason
    @provider_retryable retryable

    test "provider recovery after #{name} schedules continuation: #{retryable}" do
      {user, project} =
        project_with_installation("translate-provider@test.com", "translate-provider")

      session = session_for(user, project)
      reason = @provider_reason
      failure = {:translation_items_failed, [%{output_path: "docs/es/guide.md", reason: reason}]}

      stub(Glossia.Github.App, :installation_token, fn 42 -> {:ok, "github-token"} end)
      stub(Glossia.Translations.RepositoryRun, :run, fn _, _, _, _, _ -> {:error, failure} end)

      Oban.Testing.with_testing_mode(:manual, fn ->
        capture_log(fn -> assert {:error, ^failure} = Translate.run(session.id) end)

        assert Repo.get!(TranslationSession, session.id).status == "failed"

        continuation =
          Repo.one(
            from s in TranslationSession, where: s.continued_from_session_id == ^session.id
          )

        if @provider_retryable do
          assert continuation.status == "pending"
          assert continuation.provider_retry_count == 1

          assert continuation.publication_branch ==
                   Repo.get!(TranslationSession, session.id).publication_branch

          job =
            Repo.one!(
              from j in Oban.Job,
                where: j.args["session_id"] == ^continuation.id,
                where: j.worker == "Glossia.TranslationSessions.TranslateWorker"
            )

          assert DateTime.diff(job.scheduled_at, DateTime.utc_now()) >= 55
        else
          assert is_nil(continuation)
        end
      end)
    end
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
    assert updated.failure_kind == "translation_items_failed"

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
              validation_code: "markdown-literal-empty",
              validation_message: "private source content",
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
    assert log =~ ~s("validation_code":"markdown-literal-empty")
    assert log =~ "Markdown text-node recovery produced an empty translation"
    refute log =~ "private source content"

    [event] = Glossia.Ingestion.list_translation_session_events(session.id)
    metadata = JSON.decode!(event.metadata)
    assert hd(metadata["items"])["validation_code"] == "markdown-literal-empty"
    refute event.metadata =~ "private source content"
  end

  test "preserves both item failures and a failed final publication flush" do
    {user, project} = project_with_installation("translate-flush@test.com", "translate-flush")
    session = session_for(user, project)

    stub(Glossia.Github.App, :installation_token, fn 42 -> {:ok, "github-token"} end)

    stub(Glossia.Github.Client, :get_commit, fn _, _, _ ->
      {:error, {:api_error, 500, "TOKEN=private-output"}}
    end)

    stub(Glossia.Translations.RepositoryRun, :run, fn _, _, _, _, opts ->
      assert :ok =
               Keyword.fetch!(opts, :after_item_completed).([
                 %{path: "docs/es/complete.md", status: "added", content: "Complete"}
               ])

      {:error, {:translation_items_failed, [%{output_path: "docs/es/failed.md"}]}}
    end)

    log =
      capture_log(fn ->
        assert {:error,
                {:translation_and_publication_failed, {:translation_items_failed, [_]},
                 {:api_error, 500, "TOKEN=private-output"}}} =
                 Translate.run(session.id)
      end)

    updated = Repo.get!(TranslationSession, session.id)
    assert updated.status == "failed"
    assert updated.error =~ "Translation failed for 1 file"
    assert updated.error =~ "could not be published"
    refute updated.error =~ "private-output"
    refute log =~ "private-output"

    [event] = Glossia.Ingestion.list_translation_session_events(session.id)
    metadata = JSON.decode!(event.metadata)
    assert metadata["failure_kind"] == "translation_and_publication_failed"
    assert metadata["translation_failure"]["failure_count"] == 1
    assert metadata["publication_failure"]["publication_code"] == "publish-failed"
    refute event.metadata =~ "private-output"
  end

  test "reports a failed final flush even when every translation succeeded" do
    {user, project} =
      project_with_installation("translate-only-flush@test.com", "translate-only-flush")

    session = session_for(user, project)
    stub(Glossia.Github.App, :installation_token, fn 42 -> {:ok, "github-token"} end)

    stub(Glossia.Github.Client, :get_commit, fn _, _, _ ->
      {:error, {:api_error, 500, "TOKEN=private-output"}}
    end)

    stub(Glossia.Translations.RepositoryRun, :run, fn _, _, _, _, opts ->
      changes = [%{path: "docs/es/complete.md", status: "added", content: "Complete"}]
      assert :ok = Keyword.fetch!(opts, :after_item_completed).(changes)
      {:ok, changes}
    end)

    log =
      capture_log(fn ->
        assert {:error,
                {:translation_publication_failed, {:api_error, 500, "TOKEN=private-output"}}} =
                 Translate.run(session.id)
      end)

    updated = Repo.get!(TranslationSession, session.id)
    assert updated.error =~ "could not be published"
    refute updated.error =~ "private-output"
    refute log =~ "private-output"
    [event] = Glossia.Ingestion.list_translation_session_events(session.id)
    assert JSON.decode!(event.metadata)["publication_code"] == "publish-failed"
  end

  test "records safe diagnostics when the final manifest cannot be collected" do
    {user, project} =
      project_with_installation("translate-manifest@test.com", "translate-manifest")

    session = session_for(user, project)
    stub(Glossia.Github.App, :installation_token, fn 42 -> {:ok, "github-token"} end)

    stub(Glossia.Translations.RepositoryRun, :run, fn _, _, _, _, _ ->
      {:error, {:translation_publication_failed, {:git_status_failed, 128}}}
    end)

    capture_log(fn ->
      assert {:error, {:translation_publication_failed, {:git_status_failed, 128}}} =
               Translate.run(session.id)
    end)

    updated = Repo.get!(TranslationSession, session.id)
    assert updated.error =~ "could not be published"
    [event] = Glossia.Ingestion.list_translation_session_events(session.id)
    assert JSON.decode!(event.metadata)["publication_code"] == "manifest-command"
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
