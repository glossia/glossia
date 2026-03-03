defmodule Glossia.TranslationSessions.TranslateWorker do
  @moduledoc """
  Oban worker that creates a translation session for a commit,
  cancelling any active sessions for the same project first.
  """

  use Oban.Worker, queue: :default, max_attempts: 3, unique: [keys: [:project_id, :commit_sha]]

  alias Glossia.TranslationSessions

  require Logger

  @impl Oban.Worker
  def perform(%Oban.Job{
        args: %{
          "project_id" => project_id,
          "commit_sha" => commit_sha,
          "commit_message" => commit_message
        }
      }) do
    project =
      Glossia.Repo.get!(Glossia.Accounts.Project, project_id)
      |> Glossia.Repo.preload(:account)

    account = project.account

    {:ok, cancelled_count} = TranslationSessions.cancel_active_sessions(project)

    if cancelled_count > 0 do
      Logger.info("Cancelled #{cancelled_count} active session(s) for project #{project_id}")
    end

    target_languages = project.setup_target_languages || []

    if target_languages == [] do
      Logger.warning("No target languages configured for project #{project_id}, skipping")
      :ok
    else
      {:ok, session} =
        TranslationSessions.create_session(account, project, %{
          "commit_sha" => commit_sha,
          "commit_message" => commit_message,
          "status" => "pending",
          "source_language" => "en",
          "target_languages" => target_languages
        })

      Glossia.Auditing.record("translation_session.created", account, nil,
        resource_type: "translation_session",
        resource_id: to_string(session.id),
        metadata: JSON.encode!(%{triggered_by: "webhook", commit_sha: commit_sha})
      )

      Logger.info("Created translation session #{session.id} for commit #{commit_sha}")

      :ok
    end
  end
end
