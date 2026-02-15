defmodule Glossia.Projects do
  alias Glossia.Accounts.{Account, Project}
  alias Glossia.Repo

  import Ecto.Query

  def create_project(%Account{id: account_id}, attrs) do
    %Project{account_id: account_id}
    |> Project.changeset(attrs)
    |> Repo.insert()
  end

  def get_project(%Account{id: account_id}, handle) do
    Project
    |> where(account_id: ^account_id, handle: ^handle)
    |> preload(:account)
    |> Repo.one()
  end

  def list_projects(%Account{id: account_id}, params \\ %{}) do
    query =
      Project
      |> where(account_id: ^account_id)
      |> preload(:account)

    Flop.validate_and_run(query, params, for: Project)
  end
end
