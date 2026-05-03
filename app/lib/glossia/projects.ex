defmodule Glossia.Projects do
  require OpenTelemetry.Tracer, as: Tracer

  alias Glossia.Accounts.{Account, Project}
  alias Glossia.Events
  alias Glossia.Repo

  import Ecto.Query

  def create_project(%Account{id: account_id} = account, attrs, opts \\ []) do
    Tracer.with_span "glossia.projects.create_project" do
      Tracer.set_attributes([{"glossia.account.id", to_string(account_id)}])

      %Project{account_id: account_id}
      |> Project.changeset(attrs)
      |> Repo.insert()
      |> case do
        {:ok, project} = ok ->
          if actor = Keyword.get(opts, :actor) do
            Events.emit("project.created", account, actor,
              resource_type: "project",
              resource_id: to_string(project.id),
              resource_path: "/#{account.handle}/#{project.handle}",
              summary: "Created project #{project.handle}",
              via: Keyword.get(opts, :via)
            )
          end

          ok

        other ->
          other
      end
    end
  end

  def create_project_from_github(
        %Account{id: account_id} = account,
        installation_id,
        attrs,
        opts \\ []
      ) do
    Tracer.with_span "glossia.projects.create_project_from_github" do
      Tracer.set_attributes([{"glossia.account.id", to_string(account_id)}])

      %Project{account_id: account_id, github_installation_id: installation_id}
      |> Project.changeset(attrs)
      |> Repo.insert()
      |> case do
        {:ok, project} = ok ->
          if actor = Keyword.get(opts, :actor) do
            repo_name =
              attrs[:github_repo_full_name] || attrs["github_repo_full_name"] || project.handle

            Events.emit("project.created", account, actor,
              resource_type: "project",
              resource_id: to_string(project.id),
              resource_path: "/#{account.handle}/#{project.handle}",
              summary: "Imported project #{project.handle} from #{repo_name}",
              via: Keyword.get(opts, :via)
            )
          end

          ok

        other ->
          other
      end
    end
  end

  def update_project_setup_status(project, status, error \\ nil) do
    project
    |> Ecto.Changeset.change()
    |> Ecto.Changeset.force_change(:setup_status, status)
    |> Ecto.Changeset.force_change(:setup_error, error)
    |> Repo.update()
  end

  def get_project(%Account{id: account_id}, handle) do
    Tracer.with_span "glossia.projects.get_project" do
      Tracer.set_attributes([
        {"glossia.account.id", to_string(account_id)},
        {"glossia.project.handle", if(is_binary(handle), do: handle, else: "")}
      ])

      Project
      |> where(account_id: ^account_id, handle: ^handle)
      |> preload(:account)
      |> Repo.one()
    end
  end

  def list_projects(%Account{id: account_id}, params \\ %{}) do
    Tracer.with_span "glossia.projects.list_projects" do
      Tracer.set_attributes([{"glossia.account.id", to_string(account_id)}])

      query =
        Project
        |> where(account_id: ^account_id)
        |> preload(:account)

      Flop.validate_and_run(query, params, for: Project)
    end
  end

  def list_imported_github_repositories(%Account{id: account_id}) do
    Tracer.with_span "glossia.projects.list_imported_github_repositories" do
      Tracer.set_attributes([{"glossia.account.id", to_string(account_id)}])

      Project
      |> where(account_id: ^account_id)
      |> where([p], not is_nil(p.github_repo_id) or not is_nil(p.github_repo_full_name))
      |> select([p], %{
        github_repo_id: p.github_repo_id,
        github_repo_full_name: p.github_repo_full_name
      })
      |> Repo.all()
    end
  end

  def update_project(%Project{} = project, attrs, opts \\ []) do
    Tracer.with_span "glossia.projects.update_project" do
      Tracer.set_attributes([{"glossia.project.id", to_string(project.id)}])

      project
      |> Project.settings_changeset(attrs)
      |> Repo.update()
      |> case do
        {:ok, updated_project} = ok ->
          if actor = Keyword.get(opts, :actor) do
            account = Repo.preload(updated_project, :account).account

            Events.emit("project.updated", account, actor,
              resource_type: "project",
              resource_id: to_string(updated_project.id),
              resource_path: "/#{account.handle}/#{updated_project.handle}",
              summary: "Updated project settings for \"#{updated_project.name}\"",
              via: Keyword.get(opts, :via)
            )
          end

          ok

        other ->
          other
      end
    end
  end

  def update_project_sandbox_id(project, sandbox_id) do
    project
    |> Ecto.Changeset.change(setup_sandbox_id: sandbox_id)
    |> Repo.update()
  end

  def list_projects_with_active_setup do
    Project
    |> where([p], p.setup_status in ["pending", "running"])
    |> Repo.all()
  end

  def subscribe_setup_events(%Project{id: project_id}) do
    Phoenix.PubSub.subscribe(Glossia.PubSub, "project_setup:#{project_id}")
  end

  def broadcast_setup_event(%Project{id: project_id}, event) do
    Phoenix.PubSub.broadcast(
      Glossia.PubSub,
      "project_setup:#{project_id}",
      {:setup_event, event}
    )
  end

  def broadcast_setup_status(%Project{id: project_id}, status) do
    Phoenix.PubSub.broadcast(
      Glossia.PubSub,
      "project_setup:#{project_id}",
      {:setup_status, status}
    )
  end
end
