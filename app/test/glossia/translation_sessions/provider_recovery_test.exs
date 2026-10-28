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
        target_languages: ["es"],
        engine_retry_count: 2,
        previous_engine_images: ["old-engine"]
      })

    %{session: session}
  end

  test "schedules one delayed continuation with the existing branch", %{session: session} do
    Oban.Testing.with_testing_mode(:manual, fn ->
      assert {:ok, continuation} = ProviderRecovery.schedule(session)
      assert continuation.status == "pending"
      assert continuation.provider_retry_count == 1
      assert continuation.engine_retry_count == 2
      assert continuation.previous_engine_images == ["old-engine"]
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

  for status <- ["pending", "running", "awaiting_input", "completed"] do
    @newer_status status

    test "a newer #{@newer_status} session prevents an old failure from creating another run", %{
      session: session
    } do
      Repo.insert!(%TranslationSession{
        account_id: session.account_id,
        project_id: session.project_id,
        status: @newer_status,
        commit_sha: "newer"
      })

      assert {:ok, nil} = ProviderRecovery.schedule(session)
    end
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

  test "retains retryable provider recovery when final publication also fails" do
    for reason <- [
          %{kind: "provider-rate-limit", status: 429},
          %{kind: "provider-timeout"},
          %{kind: "provider-error", status: 504}
        ] do
      translation = {:translation_items_failed, [%{reason: reason}]}

      assert ProviderRecovery.retryable_provider_failure?(
               {:translation_and_publication_failed, translation, :github_down}
             )
    end

    refute ProviderRecovery.retryable_provider_failure?(
             {:translation_publication_failed, :github_down}
           )

    refute ProviderRecovery.retryable_provider_failure?(
             {:translation_and_publication_failed,
              {:translation_items_failed, [%{reason: %{kind: "validation"}}]}, :github_down}
           )
  end

  test "only normalized retryable provider failures trigger recovery" do
    for reason <- [
          %{kind: "validation", scope: "item"},
          %{kind: "provider-credentials", status: 401},
          %{kind: "provider-credit", status: 402},
          %{kind: "provider-error", status: 400},
          %{kind: "provider-timeout", status: 404},
          nil
        ] do
      refute ProviderRecovery.retryable_provider_failure?(
               {:translation_items_failed, [%{reason: reason}]}
             )
    end

    refute ProviderRecovery.retryable_provider_failure?({:translation_items_failed, [%{}]})

    for reason <- [
          %{kind: "provider-rate-limit", scope: "session"},
          %{"kind" => "provider-error", "status" => "504"},
          {:llm_failed, :timeout},
          {:llm_failed, %Req.TransportError{reason: :closed}}
        ] do
      assert ProviderRecovery.retryable_provider_failure?(
               {:translation_items_failed, [%{reason: reason}]}
             )
    end
  end
end
