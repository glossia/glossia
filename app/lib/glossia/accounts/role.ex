defmodule Glossia.Accounts.Role do
  use Glossia.Schema
  import Ecto.Changeset

  schema "roles" do
    field :name, :string
    field :scope, :string

    has_many :user_roles, Glossia.Accounts.UserRole

    timestamps()
  end

  def changeset(role, attrs) do
    role
    |> cast(attrs, [:name, :scope])
    |> validate_required([:name, :scope])
    |> validate_inclusion(:scope, ["instance", "organization"])
    |> unique_constraint([:scope, :name])
  end
end
