defmodule Glossia.Accounts.Identity do
  use Glossia.Schema
  import Ecto.Changeset

  schema "identities" do
    field :provider, :string
    field :provider_uid, :string
    field :provider_token, :string
    field :provider_refresh_token, :string

    belongs_to :user, Glossia.Accounts.User

    timestamps()
  end

  def changeset(identity, attrs) do
    identity
    |> cast(attrs, [:provider, :provider_uid, :provider_token, :provider_refresh_token])
    |> validate_required([:provider, :provider_uid])
    |> unique_constraint([:provider, :provider_uid])
  end
end
