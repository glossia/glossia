defmodule Glossia.Localizations do
  @moduledoc false

  alias Glossia.Localizations.Workers.LocalizeWorker
  alias Glossia.Projects
  alias Glossia.Projects.Project
  @behaviour Glossia.Authorization.Policy

  # Types
  @type process_localization_opts :: %{project_id: number()}

  @doc """
  It processes a localization

  ## Parameteres

  - `localization` - The localization to process.
  - `opts` - The options to process the localization request.
  """
  @spec process_localization(
          localization :: any(),
          opts :: process_localization_opts()
        ) :: :ok | {:error, term()}
  def process_localization(localization, %{project_id: project_id} = _opts) do
    project = Projects.find_project_by_id(project_id)

    content_source = Glossia.ContentSources.content_source(project.content_source_platform)

    version = localization.version

    unique_id =
      case content_source.get_content_branch_id(project.content_source_id, %{version: version}) do
        nil -> version
        id -> id
      end

    %{localization: localization, project_id: project_id, unique_id: unique_id}
    |> LocalizeWorker.new(replace: [:args])
    |> Oban.insert()
    |> case do
      {:ok, _} -> :ok
      {:error, error} -> {:error, error}
    end
  end

  def authorize(:create, %Project{} = authenticated_project, %Project{} = project) do
    if authenticated_project.id == project.id, do: :ok, else: :error
  end
end
