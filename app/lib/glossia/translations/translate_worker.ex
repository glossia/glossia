defmodule Glossia.Translations.TranslateWorker do
  @moduledoc """
  Oban worker that creates a translation for a commit,
  cancelling any active translations for the same project first,
  then delegates to the Translate orchestrator.
  """

  use Oban.Worker, queue: :default, max_attempts: 3, unique: [keys: [:project_id, :commit_sha]]

  alias Glossia.Translations

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
      |> Glossia.Repo.preload([:account, :github_installation])

    account = project.account

    {:ok, cancelled_count} = Translations.cancel_active_translations(project)

    if cancelled_count > 0 do
      Logger.info("Cancelled #{cancelled_count} active translation(s) for project #{project_id}")
    end

    target_languages = project.setup_target_languages || []

    if target_languages == [] do
      Logger.warning("No target languages configured for project #{project_id}, skipping")
      :ok
    else
      {:ok, translation} =
        Translations.create_translation(account, project, %{
          "commit_sha" => commit_sha,
          "commit_message" => commit_message,
          "status" => "pending",
          "source_language" => "en",
          "target_languages" => target_languages
        })

      Glossia.Auditing.record("translation.created", account, nil,
        resource_type: "translation",
        resource_id: to_string(translation.id),
        metadata: JSON.encode!(%{triggered_by: "webhook", commit_sha: commit_sha})
      )

      Logger.info("Created translation #{translation.id} for commit #{commit_sha}")

      Glossia.Translations.Translate.run(project, account, translation)
    end
  end
end
