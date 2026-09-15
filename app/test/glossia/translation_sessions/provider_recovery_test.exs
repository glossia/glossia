defmodule Glossia.TranslationSessions.ProviderRecoveryTest do
  use Glossia.DataCase, async: true
  alias Glossia.Accounts.Project
  alias Glossia.TestHelpers
  alias Glossia.TranslationSessions.{ProviderRecovery, TranslationSession, TranslateWorker}

  setup do
    user = TestHelpers.create_user("provider-recovery@test.com", "provider-recovery")

    project =
      Repo.insert!(%Project{account_id: user.account.id, handle: "recovery", name: "Recovery"})

    session =
      Repo.insert!(%TranslationSession{
        account_id: user.account.id,
        project_id: project.id,
        status: "failed",
        commit_sha: "source",
        publication_branch: "glossia/translate/source",
        publication_commit_sha: "checkpoint",
        target_languages: ["es"]
      })

    %{session: session}
  end

  test "schedules one delayed continuation with the existing branch", %{session: session} do
    Oban.Testing.with_testing_mode(:manual, fn ->
      assert {:ok, continuation} = ProviderRecovery.schedule(session)
      assert continuation.status == "pending"
      assert continuation.provider_retry_count == 1
      assert continuation.continued_from_session_id == session.id
      assert continuation.publication_branch == session.publication_branch
      assert continuation.publication_commit_sha == "checkpoint"

      job =
        Repo.one!(
          from j in Oban.Job,
            where:
              j.worker == ^to_string(TranslateWorker) or
                j.worker == "Glossia.TranslationSessions.TranslateWorker"
        )

      assert job.args["session_id"] == continuation.id
      assert DateTime.diff(job.scheduled_at, DateTime.utc_now()) >= 55
      assert {:ok, nil} = ProviderRecovery.schedule(session)
    end)
  end

  test "a newer session prevents an old failure from creating another run", %{session: session} do
    Repo.insert!(%TranslationSession{
      account_id: session.account_id,
      project_id: session.project_id,
      status: "running",
      commit_sha: "newer"
    })

    assert {:ok, nil} = ProviderRecovery.schedule(session)
  end

  test "automatic recovery is bounded and cancelled sessions are never revived", %{
    session: session
  } do
    session |> Ecto.Changeset.change(provider_retry_count: 6) |> Repo.update!()
    assert {:ok, nil} = ProviderRecovery.schedule(session)

    session
    |> Ecto.Changeset.change(provider_retry_count: 0, status: "cancelled")
    |> Repo.update!()

    assert {:ok, nil} = ProviderRecovery.schedule(session)
  end

  test "validation failures alone do not trigger provider recovery" do
    refute ProviderRecovery.rate_limited?(
             {:translation_items_failed, [%{reason: %{kind: "validation", scope: "item"}}]}
           )

    refute ProviderRecovery.rate_limited?({:translation_items_failed, [%{}]})

    assert ProviderRecovery.rate_limited?(
             {:translation_items_failed,
              [%{reason: %{kind: "provider-rate-limit", scope: "session"}}]}
           )
  end
end
