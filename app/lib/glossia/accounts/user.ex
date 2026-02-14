defmodule Glossia.Accounts.User do
  use Glossia.Schema
  import Ecto.Changeset

  schema "users" do
    field :email, :string
    field :name, :string
    field :avatar_url, :string
    field :has_access, :boolean, default: false

    belongs_to :account, Glossia.Accounts.Account
    has_many :identities, Glossia.Accounts.Identity
    has_many :organization_memberships, Glossia.Accounts.OrganizationMembership

    timestamps()
  end

  def changeset(user, attrs) do
    user
    |> cast(attrs, [:email, :name, :avatar_url, :has_access])
    |> validate_required([:email])
    |> validate_format(:email, ~r/@/)
    |> unique_constraint(:email)
    |> unique_constraint(:account_id)
  end
end
