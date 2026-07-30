defmodule Glossia.Accounts.RoleAssignment do
  use Glossia.Schema
  import Ecto.Changeset

  schema "role_assignments" do
    belongs_to :user, Glossia.Accounts.User
    belongs_to :role, Glossia.Accounts.Role
    belongs_to :organization, Glossia.Accounts.Organization

    timestamps()
  end

  def changeset(assignment, attrs) do
    assignment
    |> cast(attrs, [])
    |> unique_constraint([:user_id, :role_id, :organization_id])
  end
end
