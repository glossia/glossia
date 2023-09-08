defmodule Glossia.Foundation.Localizations.Core.Workers.LocalizeWorker do
  @moduledoc """
  It processes the events that are triggered by the version control system.
  """

  # Modules
  use Oban.Worker, unique: [keys: [:unique_id], states: [:available, :scheduled, :executing]]
  require Logger
  alias Glossia.Foundation.Projects.Core, as: Projects
  alias Glossia.Foundation.ContentSources.Core, as: ContentSources
  alias Glossia.Foundation.Localizations.Core.Utilities.Parser
  alias Glossia.Foundation.Localizations.Core.Utilities.Localizer

  # Impl: Oban.Worker

  @impl Oban.Worker
  def perform(job) do
    request = job.args["request"] |> Useful.atomize_map_keys()
    Logger.info("Processing localization request", request)
    version = request[:version]
    project = Projects.find_project_by_id(job.args["project_id"])

    content_source =
      ContentSources.new(project.content_source_platform, project.content_source_id)

    content_changes = Parser.parse_localization_request(request)
    content_update = Localizer.localize(content_source, version, content_changes)

    # TODO
    # - Update the lockfiles to ensure translations happen incrementally
    # - Set the right title and description
    # - Create a localization request in the database
    # - Update the costs as localizations are happening
    # - Update the Stripe plan accordingly

    content_source
    |> ContentSources.update_content(Map.merge(content_update, %{version: version}))
    |> case do
      {:error, :newer_version_exists} -> :ok
      {:error, error} -> {:error, error}
      {:ok, _} -> :ok
    end
  end
end
