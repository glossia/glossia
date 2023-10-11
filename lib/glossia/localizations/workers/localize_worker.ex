defmodule Glossia.Localizations.Workers.LocalizeWorker do
  @moduledoc """
  It processes the events that are triggered by the version control system.
  """

  # Modules
  use Oban.Worker, unique: [keys: [:unique_id], states: [:available, :scheduled, :executing]]
  require Logger
  alias Glossia.Projects, as: Projects
  alias Glossia.ContentSources, as: ContentSources
  alias Glossia.Localizations.Utilities.Parser
  alias Glossia.Localizations.Utilities.Localizer

  # Impl: Oban.Worker

  @impl Oban.Worker
  def perform(job) do
    localization = job.args["localization"] |> Useful.atomize_map_keys()
    Logger.info("Processing localization", localization)
    version = localization[:version]
    project = Projects.find_project_by_id(job.args["project_id"])

    content_source =
      ContentSources.new(project.content_source_platform, project.content_source_id)

    content_changes = Parser.parse_localization(localization)
    _content_updates = Localizer.localize(content_source, version, content_changes)

    :ok
    # content_source
    # |> ContentSources.update_content(Map.merge(content_updates, %{version: version}))
    # |> case do
    #   {:error, :newer_version_exists} -> :ok
    #   {:error, error} -> {:error, error}
    #   {:ok, _} -> :ok
    # end
  end
end
