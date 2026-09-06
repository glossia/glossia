defmodule Glossia.TranslationSessions.ContinuousTranslationWorkerTest do
  use Glossia.DataCase, async: true
  use Mimic

  alias Glossia.Projects
  alias Glossia.TestHelpers
  alias Glossia.TranslationSessions.ContinuousTranslationWorker

  test "ignores a delayed push when the default branch has already advanced" do
    user = TestHelpers.create_user("stale-push@test.com", "stale-push")

    {:ok, project} =
      Projects.create_project(user.account, %{
        handle: "stale-push-project",
        name: "Stale push project",
        github_repo_id: 9_003,
        github_repo_full_name: "example/stale-push",
        github_repo_default_branch: "main",
        setup_target_languages: ["es"]
      })

    Mimic.expect(Glossia.Github.Client, :get_ref, fn "example/stale-push", "heads/main", nil ->
      {:ok, %{"object" => %{"sha" => "newer-commit"}}}
    end)

    Mimic.expect(Glossia.Github.Client, :compare_commits, fn "example/stale-push",
                                                             "older-commit",
                                                             "newer-commit",
                                                             nil ->
      {:ok, %{"status" => "ahead"}}
    end)

    Mimic.expect(Glossia.TranslationSessions, :start_continuous_session, fn received_project,
                                                                            attrs,
                                                                            opts ->
      assert received_project.id == project.id
      assert attrs.commit_sha == "older-commit"
      assert {:ignore, :stale_push} = opts |> Keyword.fetch!(:validate) |> then(& &1.())
      {:ignored, :stale_push}
    end)

    assert :ok =
             ContinuousTranslationWorker.perform(%Oban.Job{
               args: %{
                 "project_id" => project.id,
                 "commit_sha" => "older-commit",
                 "commit_message" => "Older commit",
                 "source_language" => "en",
                 "target_languages" => ["es"]
               }
             })
  end

  test "retries when the pushed commit is newer than GitHub's visible branch head" do
    user = TestHelpers.create_user("lagging-push@test.com", "lagging-push")

    {:ok, project} =
      Projects.create_project(user.account, %{
        handle: "lagging-push-project",
        name: "Lagging push project",
        github_repo_id: 9_005,
        github_repo_full_name: "example/lagging-push",
        github_repo_default_branch: "main",
        setup_target_languages: ["es"]
      })

    Mimic.expect(Glossia.Github.Client, :get_ref, fn "example/lagging-push", "heads/main", nil ->
      {:ok, %{"object" => %{"sha" => "older-visible-commit"}}}
    end)

    Mimic.expect(Glossia.Github.Client, :compare_commits, fn "example/lagging-push",
                                                             "newly-pushed-commit",
                                                             "older-visible-commit",
                                                             nil ->
      {:ok, %{"status" => "behind"}}
    end)

    Mimic.expect(Glossia.TranslationSessions, :start_continuous_session, fn _project,
                                                                            _attrs,
                                                                            opts ->
      assert {:error, :default_branch_not_visible_yet} =
               opts |> Keyword.fetch!(:validate) |> then(& &1.())

      {:error, :default_branch_not_visible_yet}
    end)

    assert {:error, :default_branch_not_visible_yet} =
             ContinuousTranslationWorker.perform(%Oban.Job{
               args: %{
                 "project_id" => project.id,
                 "commit_sha" => "newly-pushed-commit",
                 "commit_message" => "New commit",
                 "source_language" => "en",
                 "target_languages" => ["es"]
               }
             })
  end
end
