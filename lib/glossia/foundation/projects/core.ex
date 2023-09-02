defmodule Glossia.Foundation.Projects.Core do
  use Boundary,
    deps: [Glossia.Repo, Glossia.Foundation.Builds.Core, Glossia.Foundation.ContentSources.Core],
    exports: [Project, ProjectToken]

  # Modules
  require Logger
  alias Glossia.Repo
  alias Glossia.Foundation.Projects.Core.{Project, ProjectToken}
  alias Glossia.Foundation.ContentSources.Core, as: ContentSources

  @doc """
  It simulates a git push event using the latest commit from the default branch of a project.
  """
  @spec simulate_new_content_event(Project.t()) :: :ok
  def simulate_new_content_event(project) do
    project
    |> trigger_build(%{
      type: "new_content",
      commit_sha: "TODO"
    })
  end

  @doc """
  Given a git event, it processes it.
  """
  def trigger_build(
        project,
        %{type: "new_content", version: version}
      ) do
    project = project |> Repo.preload(:account)

    content_source =
      ContentSources.new(project.content_source_platform, project.content_source_id)

    {:ok, access_token} = ContentSources.generate_auth_token(content_source)

    :ok =
      %{
        type: "new_version",
        version: version,
        content_source_id: project.content_source_id,
        content_source_platform: project.content_source_platform,
        project_id: project.id,
        project_handle: project.handle,
        account_handle: project.account.handle
      }
      |> Map.put(:access_token, generate_token_for_project(project))
      |> Map.put(
        :content_source_access_token,
        access_token
      )
      |> Glossia.Foundation.Builds.Core.trigger_build()

    # TODO: Ignore events that are coming from a branch other than the default.
    # ["refs", "heads" | tail] = Map.fetch!(attrs, :ref) |> String.split("/")
    # branch = tail |> Enum.join("/")
    :ok
  end

  def process_git_event(project, %{} = opts) do
    Logger.info("Ignoring event for project with id #{project.id}", opts)
  end

  @doc """
  Creates a new project with the given attributes.
  """
  @spec create_project(attrs :: Project.changeset_attrs()) ::
          {:ok, Project.t()} | {:error, Ecto.Changeset.t()}
  def create_project(attrs) do
    %Project{} |> Project.changeset(attrs) |> Repo.insert()
  end

  @doc """
  It finds a repository given the id and the vcs.
  """
  @spec find_project_by_repository(%{
          content_source_id: String.t(),
          content_source_platform: Project.vcs()
        }) ::
          Project.t() | nil
  def find_project_by_repository(attrs) do
    Project.find_project_by_repository_query(attrs) |> Repo.one()
  end

  @doc """
  It finds a project given the id.
  """
  def find_project_by_id(id) do
    Repo.get_by(Project, id: id)
  end

  @doc """
  It finds a project given the owner and the project handle.
  """
  @spec find_project_by_owner_and_project_handle(owner :: String.t(), project :: String.t()) ::
          Project.t() | nil
  def find_project_by_owner_and_project_handle(owner, project) do
    Project.find_project_by_owner_and_project_handle_query(owner, project) |> Repo.one()
  end

  @doc """
  It generates a token for the given project to authenticate requests coming from builds.
  """
  @spec generate_token_for_project(Project.t()) :: String.t()
  def generate_token_for_project(project) do
    {:ok, token, _claims} = ProjectToken.generate_token_for_project_with_id(project.id)
    token
  end

  @doc """
  It generates a token for the given project id to authenticate requests coming from builds.
  """
  @spec generate_token_for_project_with_id(String.t()) :: String.t()
  def generate_token_for_project_with_id(project_id) do
    {:ok, token, _claims} = ProjectToken.generate_token_for_project_with_id(project_id)
    token
  end

  @doc """
  It gets the project from the given token. If the project does not exist, it returns nil.
  """
  @spec get_project_from_token(String.t()) :: Project.t() | nil
  def get_project_from_token(token) do
    case ProjectToken.get_project_id_from_token(token) do
      {:ok, project_id} ->
        Repo.get(Project, project_id)

      {:error, _} ->
        nil
    end
  end
end
