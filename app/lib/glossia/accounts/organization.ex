defmodule Glossia.Accounts.Organization do
  use Glossia.Schema
  import Ecto.Changeset

  schema "organizations" do
    field :auth_provider, :string
    field :auth_domain, :string
    field :auth_domain_token, :string
    field :auth_domain_verified_at, :utc_datetime_usec
    field :auth_issuer, :string
    field :auth_client_id, :string
    field :auth_client_secret, Glossia.Encrypted.Binary, redact: true
    field :name, :string
    field :claimable, :boolean, default: false

    belongs_to :account, Glossia.Accounts.Account
    has_many :organization_memberships, Glossia.Accounts.OrganizationMembership
    has_many :user_roles, Glossia.Accounts.UserRole

    timestamps()
  end

  def changeset(organization, attrs) do
    organization
    |> cast(attrs, [:name])
    |> validate_required([:name])
    |> unique_constraint(:account_id)
  end
end
