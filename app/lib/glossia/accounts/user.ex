defmodule Glossia.Accounts.User do
  use Glossia.Schema
  import Ecto.Changeset

  schema "users" do
    field :email, :string
    field :name, :string
    field :avatar_url, :string
    field :bio, :string
    field :github_url, :string
    field :x_url, :string
    field :linkedin_url, :string
    field :mastodon_url, :string
    field :has_access, :boolean, default: false
    field :super_admin, :boolean, default: false

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

  def profile_changeset(user, attrs) do
    user
    |> cast(attrs, [:name, :avatar_url, :bio, :github_url, :x_url, :linkedin_url, :mastodon_url])
    |> validate_length(:name, max: 100)
    |> validate_length(:bio, max: 500)
    |> validate_url(:github_url)
    |> validate_url(:x_url)
    |> validate_url(:linkedin_url)
    |> validate_url(:mastodon_url)
  end

  defp validate_url(changeset, field) do
    validate_change(changeset, field, fn _, value ->
      if value == "" or is_nil(value) do
        []
      else
        if String.starts_with?(value, "https://") do
          []
        else
          [{field, "must start with https://"}]
        end
      end
    end)
  end
end
