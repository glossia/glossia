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

  def update_project_setup_status_if_sandbox_id(
        %Project{id: project_id},
        expected_sandbox_id,
        status,
        error \\ nil
      ) do
    now = DateTime.utc_now()

    query =
      Project
      |> where(id: ^project_id)
      |> where_expected_setup_sandbox_id(expected_sandbox_id)

    case Repo.update_all(query,
           set: [setup_status: status, setup_error: error, updated_at: now]
         ) do
      {1, _} -> {:ok, Repo.get!(Project, project_id)}
      {0, _} -> {:error, :setup_sandbox_id_changed}
    end
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
    |> Ecto.Changeset.change()
    |> Ecto.Changeset.force_change(:setup_sandbox_id, sandbox_id)
    |> Repo.update()
  end

  def replace_project_sandbox_id(%Project{id: project_id}, expected_id, sandbox_id) do
    now = DateTime.utc_now()

    query =
      Project
      |> where(id: ^project_id)
      |> where_expected_setup_sandbox_id(expected_id)

    case Repo.update_all(query,
           set: [setup_sandbox_id: sandbox_id, updated_at: now]
         ) do
      {1, _} -> {:ok, Repo.get!(Project, project_id)}
      {0, _} -> {:error, :setup_sandbox_id_changed}
    end
  end

  def list_projects_with_active_setup do
    Project
    |> where([p], p.setup_status in ["pending", "running"])
    |> Repo.all()
  end

  def list_projects_with_failed_setup do
    Project
    |> where(setup_status: "failed")
    |> Repo.all()
  end

  def reset_project_setup_for_recovery(%Project{} = project) do
    project
    |> Ecto.Changeset.change()
    |> Ecto.Changeset.force_change(:setup_status, "pending")
    |> Ecto.Changeset.force_change(:setup_error, nil)
    |> Repo.update()
  end

  def retry_project_setup(%Project{id: project_id, setup_status: "failed"}) do
    now = DateTime.utc_now()

    case Project
         |> where(id: ^project_id, setup_status: "failed")
         |> Repo.update_all(set: [setup_status: "pending", setup_error: nil, updated_at: now]) do
      {1, _} -> {:ok, Repo.get!(Project, project_id)}
      {0, _} -> {:error, :setup_not_failed}
    end
  end

  def retry_project_setup(%Project{}), do: {:error, :setup_not_failed}

  def fail_pending_project_setup(%Project{id: project_id}, error) do
    now = DateTime.utc_now()

    case Project
         |> where(id: ^project_id, setup_status: "pending")
         |> Repo.update_all(set: [setup_status: "failed", setup_error: error, updated_at: now]) do
      {1, _} -> {:ok, Repo.get!(Project, project_id)}
      {0, _} -> {:error, :setup_not_pending}
    end
  end

  def discard_pending_project_setup(%Project{} = project) do
    discard_project_setup(project, "pending", :setup_not_pending)
  end

  def discard_failed_project_setup(%Project{} = project) do
    discard_project_setup(project, "failed", :setup_not_failed)
  end

  defp discard_project_setup(%Project{id: project_id}, status, mismatch_error) do
    Repo.transaction(fn ->
      case Project
           |> where(id: ^project_id, setup_status: ^status)
           |> lock("FOR UPDATE")
           |> Repo.one() do
        nil ->
          Repo.rollback(mismatch_error)

        project ->
          Repo.delete!(project)
          project
      end
    end)
  end

  defp where_expected_setup_sandbox_id(query, nil) do
    where(query, [p], is_nil(p.setup_sandbox_id))
  end

  defp where_expected_setup_sandbox_id(query, expected_id) do
    where(query, [p], p.setup_sandbox_id == ^expected_id)
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

  def broadcast_setup_failure(%Project{id: project_id}, error) do
    Phoenix.PubSub.broadcast(
      Glossia.PubSub,
      "project_setup:#{project_id}",
      {:setup_failed, project_id, error}
    )
  end
end
