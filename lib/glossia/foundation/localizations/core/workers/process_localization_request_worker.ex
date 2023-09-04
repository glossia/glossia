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

  # Impl: Oban.Worker

  @impl Oban.Worker
  def perform(job) do
    request = job.args["request"] |> Useful.atomize_map_keys()
    Logger.info("Processing localization request", request)
    version = request[:id]
    project = get_project(job.args["project_id"])

    content =
      localize_into_new_languages(
        LocalizationRequestParser.get_modules_with_new_languages_that_require_localization(request)
      ) ++
        update_localized_content_due_to_content_or_context_changes(
          get_modules_with_changed_source_context_or_content(request)
        )

    _ =
      ContentSources.new(project.content_source_platform, project.content_source_id)
      |> ContentSources.update_content(%{
        # TODO: Improve
        title: "Localization",
        description: "",
        version: version,
        content: content
      })
  end

  # Private

  defp localize_into_new_languages(_modules) do
    Logger.info("Localizing the content into new languages")
    # TODO
    []
  end

  defp update_localized_content_due_to_content_or_context_changes(_modules) do
    # TODO
    []
  end

  defp get_project(project_id) do
    Projects.find_project_by_id(project_id)
  end

  defp get_modules_with_changed_source_context_or_content(_request) do
    []
    # TODO
  end
end
