defmodule Glossia.Accounts.Organization do
  use Glossia.Schema
  import Ecto.Changeset

  schema "organizations" do
    field :name, :string

    belongs_to :account, Glossia.Accounts.Account
    has_many :organization_memberships, Glossia.Accounts.OrganizationMembership

    timestamps()
  end

  def changeset(organization, attrs) do
    organization
    |> cast(attrs, [:name])
    |> validate_required([:name])
    |> unique_constraint(:account_id)
  end
end
