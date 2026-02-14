defmodule Glossia.Accounts.Project do
  use Glossia.Schema
  import Ecto.Changeset

  schema "projects" do
    field :handle, :string
    field :name, :string

    belongs_to :account, Glossia.Accounts.Account

    timestamps()
  end

  def changeset(project, attrs) do
    project
    |> cast(attrs, [:handle, :name])
    |> validate_required([:handle, :name])
    |> validate_format(:handle, ~r/^[a-z0-9]([a-z0-9-]*[a-z0-9])?$/,
      message: "must contain only lowercase letters, numbers, and hyphens"
    )
    |> validate_length(:handle, min: 2, max: 39)
    |> unique_constraint([:account_id, :handle])
  end
end
