defmodule Glossia.Projects.Project do
  @moduledoc """
  A module that represents the projects table
  """

  # Types

  @type t :: %__MODULE__{
          handle: String.t(),
          account: Account.t() | nil,
          repository_id: String.t(),
          vcs: :github
        }
  @type vcs :: :github

  # Module dependencies

  alias Glossia.Accounts.Account
  use Ecto.Schema
  import Ecto.Changeset

  # Schema

  schema "projects" do
    field :handle, :string
    field :repository_id, :string
    field :vcs, Ecto.Enum, values: [{:github, 1}]
    belongs_to :account, Account, on_replace: :raise

    timestamps()
  end

  # Changesets

  @doc """
  It returns the base `Ecto.Changeset` to create and update projects.
  """
  @type changeset_attrs :: %{
          handle: String.t(),
          repository_id: String.t(),
          vcs: :github,
          account_id: integer()
        }
  @spec changeset(project :: t(), attrs :: changeset_attrs) :: Ecto.Changeset.t()
  def changeset(project, attrs) do
    project
    |> cast(attrs, [:handle, :repository_id, :vcs, :account_id])
    |> validate_required([:handle, :repository_id, :vcs, :account_id])
    |> validate_inclusion(:vcs, [:github])
    |> validate_format(:handle, ~r/^[a-z0-9_]+$/i, message: "must be alphanumeric")
    |> validate_length(:handle, min: 3, max: 20)
    |> unique_constraint(:handle)
    |> assoc_constraint(:account)
  end
end
