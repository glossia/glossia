defmodule Glossia.Accounts.Account do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "accounts" do
    field :handle, :string

    has_one :user, Glossia.Accounts.User
    has_one :organization, Glossia.Accounts.Organization

    timestamps(type: :utc_datetime)
  end

  def changeset(account, attrs) do
    account
    |> cast(attrs, [:handle])
    |> validate_required([:handle])
    |> validate_format(:handle, ~r/^[a-z0-9]([a-z0-9-]*[a-z0-9])?$/,
      message: "must contain only lowercase letters, numbers, and hyphens"
    )
    |> validate_length(:handle, min: 2, max: 39)
    |> unique_constraint(:handle)
  end
end
