defmodule Glossia.Foundation.Localizations.Core do
  # Modules
  use Boundary,
  deps: [Glossia.Foundation.ContentSources.Core, Glossia.Foundation.Projects.Core, Glossia.Foundation.LLMs.Core, Glossia.Foundation.Database.Core],
  exports: [API.Schemas.LocalizationRequest]
  alias Glossia.Foundation.ContentSources.Core, as: ContentSources
  alias Glossia.Localizations.API.Schemas.LocalizationRequest
  alias Glossia.Foundation.Localizations.Core.Workers.ProcessLocalizationRequestWorker
  alias Glossia.Foundation.Projects.Core, as: Projects

  # Types
  @type process_localization_request_opts :: %{project_id: number()}

  @doc """
  It processes a localization request

  ## Parameteres

  - `request` - The localization request to process.
  - `opts` - The options to process the localization request.
  """
  @spec process_localization_request(
          request :: LocalizationRequest.t(),
          opts :: process_localization_request_opts()
        ) :: :ok | {:error, term()}
  def process_localization_request(request, %{project_id: project_id} = _opts) do
    project = Projects.find_project_by_id(project_id)
    content_source = ContentSources.new(project.content_source_platform, project.content_source_id)
    version = request.version
    unique_id = case ContentSources.get_content_branch_id(content_source, %{ version: version }) do
      nil -> version
      id -> id
    end

    %{request: request, project_id: project_id, unique_id: unique_id}
    |> ProcessLocalizationRequestWorker.new(replace: [:args])
    |> Oban.insert()
    |> case do
      {:ok, _} -> :ok
      {:error, error} -> {:error, error}
    end
  end
end
