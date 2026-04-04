defmodule Glossia.Accounts.OrganizationMembership do
  use Glossia.Schema
  import Ecto.Changeset

  schema "organization_memberships" do
    field :role, :string, default: "member"

    belongs_to :user, Glossia.Accounts.User
    belongs_to :organization, Glossia.Accounts.Organization

    timestamps()
  end

  def changeset(membership, attrs) do
    membership
    |> cast(attrs, [:role])
    |> validate_required([:role])
    |> validate_inclusion(:role, ["admin", "member", "linguist"])
    |> unique_constraint([:user_id, :organization_id])
  end
end
