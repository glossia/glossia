defmodule Glossia.Projects do
  require Logger
  alias Glossia.Repo
  alias Glossia.Projects.{Project, ProjectToken}
  alias Glossia.ContentSources, as: ContentSources
  alias Glossia.Accounts.User
  import Ecto.Query, only: [from: 2]

  def get_project_by_id(id) do
    Repo.get(Project, id)
  end

  def get_account_projects(accounts) do
    Repo.all(
      from p in Project,
        where: p.account_id in ^Enum.map(accounts, & &1.id),
        order_by: [desc: p.inserted_at]
    )
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
      |> Glossia.Builds.trigger_build()

    # We should ignore events that are coming from a branch other than the default.
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
  def create_project(attrs) do
    changeset = %Project{} |> Project.changeset(attrs)
    changeset |> Repo.insert()
  end

  @doc """
  It finds a repository given the id and the vcs.
  """
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
  def find_project_by_owner_and_project_handle(owner, project) do
    Project.find_project_by_owner_and_project_handle_query(owner, project) |> Repo.one()
  end

  @doc """
  It generates a token for the given project to authenticate requests coming from builds.
  """
  def generate_token_for_project(project) do
    {:ok, token, _claims} = ProjectToken.generate_token_for_project_with_id(project.id)
    token
  end

  @doc """
  It generates a token for the given project id to authenticate requests coming from builds.
  """
  def generate_token_for_project_with_id(project_id) do
    {:ok, token, _claims} = ProjectToken.generate_token_for_project_with_id(project_id)
    token
  end

  @doc """
  It gets the project from the given token. If the project does not exist, it returns nil.
  """
  def get_project_from_token(token) do
    case ProjectToken.get_project_id_from_token(token) do
      {:ok, project_id} ->
        Repo.get(Project, project_id)

      {:error, _} ->
        nil
    end
  end

  def authorize(_, _, nil) do
    :ok
  end

  def authorize(:read, %User{} = user, %Project{} = project) do
    if Glossia.Accounts.get_user_and_organization_accounts(user)
       |> Enum.map(& &1.id)
       |> Enum.member?(project.account_id) do
      :ok
    else
      :error
    end
  end

  def authorize(:read, %Project{id: lhs_id}, %Project{id: rhs_id}) do
    if lhs_id == rhs_id, do: :ok, else: :error
  end
end
