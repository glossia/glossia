defmodule Glossia.Accounts.AccountToken do
  use Glossia.Schema
  import Ecto.Changeset

  @derive {
    Flop.Schema,
    filterable: [:name],
    sortable: [:name, :inserted_at, :last_used_at, :expires_at],
    default_order: %{order_by: [:inserted_at], order_directions: [:desc]}
  }

  schema "account_tokens" do
    field :name, :string
    field :description, :string
    field :token_hash, :string
    field :token_prefix, :string
    field :scope, :string, default: ""
    field :expires_at, :utc_datetime_usec
    field :last_used_at, :utc_datetime_usec
    field :revoked_at, :utc_datetime_usec

    belongs_to :account, Glossia.Accounts.Account
    belongs_to :user, Glossia.Accounts.User

    timestamps()
  end

  def changeset(token, attrs) do
    token
    |> cast(attrs, [:name, :description, :scope, :expires_at])
    |> validate_required([:name])
    |> validate_length(:name, min: 1, max: 255)
  end
end
