defmodule Glossia.Projects do
  require OpenTelemetry.Tracer, as: Tracer

  alias Glossia.Accounts.{Account, Project}
  alias Glossia.Repo

  import Ecto.Query

  def create_project(%Account{id: account_id}, attrs) do
    Tracer.with_span "glossia.projects.create_project" do
      Tracer.set_attributes([{"glossia.account.id", to_string(account_id)}])

      %Project{account_id: account_id}
      |> Project.changeset(attrs)
      |> Repo.insert()
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
end
