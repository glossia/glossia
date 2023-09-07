defmodule Glossia.Foundation.Localizations.Core.Workers.ProcessLocalizationRequestWorker do
  @moduledoc """
  It processes the events that are triggered by the version control system.
  """

  # Modules
  use Oban.Worker
  require Logger
  alias Glossia.Foundation.Projects.Core, as: Projects
  alias Glossia.Foundation.ContentSources.Core, as: ContentSources
  alias Glossia.Foundation.Localizations.Core.Workers.LocalizationRequestParser
  alias Glossia.Foundation.Localizations.Core.Utilities.LLMLocalizer

  # Impl: Oban.Worker

  @impl Oban.Worker
  def perform(job) do
    request = job.args["request"] |> Useful.atomize_map_keys()
    Logger.info("Processing localization request", request)
    version = request[:version]
    project = get_project(job.args["project_id"])

    content_source =
      ContentSources.new(project.content_source_platform, project.content_source_id)

    content_changes = LocalizationRequestParser.parse_localization_request(request)
    content_update = LLMLocalizer.localize(content_source, version, content_changes)

    content_source
      |> ContentSources.update_content(Map.merge(content_update, %{version: version}))
      |> case do
        {:error, :newer_version_exists} -> :ok
        {:error, error} -> {:error, error}
      end
  end

  # Private

  defp get_project(project_id) do
    Projects.find_project_by_id(project_id)
  end
end
