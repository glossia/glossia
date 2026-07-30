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
    |> unique_constraint(:role_id, name: "role_assignments_instance_user_role_unique")
    |> unique_constraint(:role_id, name: "role_assignments_org_user_role_unique")
  end
end
