defmodule Glossia.Foundation.Localizations.Core.Workers.ProcessLocalizationRequestWorker do
  @moduledoc """
  It processes the events that are triggered by the version control system.
  """

  # Modules
  require Logger
  alias Glossia.Projects
  alias Glossia.Foundation.ContentSources.Core, as: ContentSources
  alias Glossia.Foundation.Localizations.Core.API.Schemas.LocalizationRequest
  use Oban.Worker

  # Impl: Oban.Worker

  @impl Oban.Worker
  def perform(job) do
    request = job.args["request"] |> Useful.atomize_map_keys()
    Logger.info("Processing localization request", request)
    version = request[:id]
    project = get_project(job.args["project_id"])

    content =
      localize_into_new_languages(
        get_modules_with_new_languages_that_require_localization(request)
      ) ++
        update_localized_content_due_to_content_or_context_changes(
          get_modules_with_changed_source_context_or_content(request)
        )

    _ =
      ContentSources.new(project.vcs_platform, project.vcs_id)
      |> ContentSources.update_content(%{
        # TODO: Improve
        title: "Localization",
        description: "",
        version: version,
        content: content
      })
  end

  # Private

  @spec localize_into_new_languages(modules :: [map()]) :: [[id: String.t(), content: String.t()]]
  defp localize_into_new_languages(modules) do
    Logger.info("Localizing the content into new languages")
    # TODO
    []
  end

  @spec localize_into_new_languages(modules :: [map()]) :: [[id: String.t(), content: String.t()]]
  defp update_localized_content_due_to_content_or_context_changes(modules) do
    # TODO
    []
  end

  defp get_project(project_id) do
    Projects.find_project_by_id(project_id)
  end

  @spec get_modules_with_new_languages_that_require_localization(
          request :: LocalizationRequest.t()
        ) :: [map()]
  defp get_modules_with_new_languages_that_require_localization(request) do
    Enum.flat_map(request[:modules], fn module ->
      format = module[:format]
      id = module[:id]
      source_localizable = module[:localizables][:source]
      source_id = source_localizable[:id]
      source_context = source_localizable[:context]
      target_localizables = module[:localizables][:target]

      # Checksums
      source_context_current_checksum = source_localizable[:checksum][:context][:current]
      source_content_current_checksum = source_localizable[:checksum][:content][:current]
      source_context_cached_checksum = source_localizable[:checksum][:context][:cached]
      source_content_cached_checksum = source_localizable[:checksum][:content][:cached]

      # The source content or context hasn't changed
      if source_context_current_checksum == source_context_cached_checksum &&
           source_content_current_checksum == source_content_cached_checksum do
        []
      else
        Enum.flat_map(target_localizables, fn target_localizable ->
          # From the target localizables we select those that already exist but
          # need to reflect the changes.
          target_id = target_localizable[:id]
          target_context = target_localizable[:context]

          target_context_cached_checksum = target_localizable[:checksum][:context][:cached]
          target_content_cached_checksum = target_localizable[:checksum][:content][:cached]

          if !target_context_cached_checksum || !target_content_cached_checksum do
            [
              %{
                id: id,
                format: format,
                source: %{
                  id: source_id,
                  context: source_context,
                  checksum_cache_id: source_localizable[:checksum][:cache_id]
                },
                target: %{
                  id: target_id,
                  context: target_context,
                  checksum_cache_id: target_localizable[:checksum][:cache_id]
                }
              }
            ]
          else
            []
          end
        end)
      end
    end)
  end

  @spec get_modules_with_new_languages_that_require_localization(
          request :: LocalizationRequest.t()
        ) :: [map()]
  defp get_modules_with_changed_source_context_or_content(_request) do
    []
    # TODO
  end
end
