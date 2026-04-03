defmodule Glossia.Accounts.OrganizationMembership do
  use Glossia.Schema
  import Ecto.Changeset

  schema "organization_memberships" do
    field :role, :string, virtual: true, default: "member"

    belongs_to :user, Glossia.Accounts.User
    belongs_to :organization, Glossia.Accounts.Organization

    timestamps()
  end

  def changeset(membership, _attrs) do
    membership
    |> change()
    |> unique_constraint([:user_id, :organization_id])
  end
end
