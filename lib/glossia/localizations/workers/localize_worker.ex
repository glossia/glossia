defmodule Glossia.Localizations.Workers.LocalizeWorker do
  @moduledoc false

  # alias Glossia.Localizations.Utilities.Localizer
  # alias Glossia.Localizations.Utilities.Parser
  # alias Glossia.Projects, as: Projects
  require Logger
  use Oban.Worker, unique: [keys: [:unique_id], states: [:available, :scheduled, :executing]]

  # Impl: Oban.Worker

  @impl Oban.Worker
  def perform(_job) do
    :ok
    # localization = job.args["localization"] |> Useful.atomize_map_keys()
    # Logger.info("Processing localization", localization)
    # version = localization[:version]
    # project = Projects.find_project_by_id(job.args["project_id"])

    # content_platform_module =
    #   Glossia.ContentSources.get_platform_module(project.content_platform)

    # content_changes = Parser.parse_localization(localization)

    # _content_updates =
    #   Localizer.localize(
    #     content_platform_module,
    #     project.id_in_content_platform,
    #     version,
    #     content_changes
    #   )

    # :ok
    # content_source
    # |> Glossia.ContentSources.update_content(Map.merge(content_updates, %{version: version}))
    # |> case do
    #   {:error, :newer_version_exists} -> :ok
    #   {:error, error} -> {:error, error}
    #   {:ok, _} -> :ok
    # end
  end
end
