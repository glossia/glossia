defmodule Glossia.Accounts.Identity do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "identities" do
    field :provider, :string
    field :provider_uid, :string
    field :provider_token, :string
    field :provider_refresh_token, :string

    belongs_to :user, Glossia.Accounts.User

    timestamps(type: :utc_datetime)
  end

  def changeset(identity, attrs) do
    identity
    |> cast(attrs, [:provider, :provider_uid, :provider_token, :provider_refresh_token])
    |> validate_required([:provider, :provider_uid])
    |> unique_constraint([:provider, :provider_uid])
  end
end
