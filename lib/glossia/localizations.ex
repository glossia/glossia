defmodule Glossia.Localizations do
  @moduledoc false

  # alias Glossia.Localizations.Workers.LocalizeWorker
  @behaviour Glossia.Authorization.Policy

  # Types
  @type process_localization_opts :: %{project_id: number()}

  @doc ~S"""
  It processes a localization

  ## Parameteres

  - `localization` - The localization to process.
  - `opts` - The options to process the localization request.
  """
  @spec process_localization(
          localization :: any(),
          opts :: process_localization_opts()
        ) :: :ok | {:error, term()}
  def process_localization(_localization, %{project_id: _project_id} = _opts) do
    :ok
    # project = Projects.find_project_by_id(project_id)

    # platform_module =
    #   Glossia.ContentSources.get_platform_module(project.platform)

    # version = localization.version

    # unique_id =
    #   case platform_module.get_content_branch_id(
    #          project.id_in_platform,
    #          %{version: version}
    #        ) do
    #     nil -> version
    #     id -> id
    #   end

    # %{localization: localization, project_id: project_id, unique_id: unique_id}
    # |> LocalizeWorker.new(replace: [:args])
    # |> Oban.insert()
    # |> case do
    #   {:ok, _} -> :ok
    #   {:error, error} -> {:error, error}
    # end
  end

  def authorize(_action, _subject, _object) do
    :ok
  end
end
