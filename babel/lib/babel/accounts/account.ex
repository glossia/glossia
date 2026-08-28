defmodule Babel.Accounts.Account do
  use Ecto.Schema

  import Ecto.Changeset

  schema "accounts" do
    field :email, :string
    field :last_seen_at, :utc_datetime
    field :name, :string
    field :pomerium_id, :string

    timestamps(type: :utc_datetime)
  end

  def registration_changeset(account, attributes) do
    account
    |> cast(attributes, [:email, :name, :pomerium_id, :last_seen_at])
    |> validate_required([:email, :pomerium_id, :last_seen_at])
    |> unique_constraint(:email)
    |> unique_constraint(:pomerium_id)
  end

  def identity_changeset(account, attributes) do
    change(account, attributes)
  end
end
