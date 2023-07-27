defmodule Glossia.Projects.Project do
  use Boundary

  @moduledoc """
  A module that represents the projects table
  """

  # Types

  @type t :: %__MODULE__{
          handle: String.t(),
          account: Account.t() | nil,
          type: type(),
          vcs_id: String.t(),
          vcs_platform: Glossia.VCS.t(),
          visibility: visibility()
        }
  @type visibility :: :public | :private
  @type type :: :git

  # Module dependencies

  alias Glossia.Accounts.Account
  alias Glossia.Builds.Build
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query, only: [from: 2]

  # Schema

  schema "projects" do
    field :handle, :string
    field :type, Ecto.Enum, values: [{:git, 1}], default: :git
    field :vcs_id, :string
    field :vcs_platform, Ecto.Enum, values: [{:github, 1}]
    field :visibility, Ecto.Enum, values: [{:private, 1}, {:public, 2}]
    belongs_to :account, Account, on_replace: :raise
    has_many(:builds, Build)

    timestamps()
  end

  # Changesets

  @doc """
  It returns the base `Ecto.Changeset` to create and update projects.
  """
  @type changeset_attrs :: %{
          handle: String.t(),
          vcs_id: String.t(),
          vcs_platform: Glossia.VCS.t(),
          account_id: integer()
        }
  @spec changeset(project :: t(), attrs :: changeset_attrs()) :: Ecto.Changeset.t()
  def changeset(project, attrs) do
    project
    |> cast(attrs, [:handle, :vcs_id, :vcs_platform, :account_id, :visibility, :type])
    |> validate_required([:handle, :vcs_id, :vcs_platform, :account_id, :type])
    |> validate_inclusion(:vcs_platform, [:github])
    |> validate_inclusion(:type, [:git])
    |> validate_format(:handle, ~r/^[a-z0-9_]+$/i, message: "must be alphanumeric")
    |> validate_length(:handle, min: 3, max: 20)
    |> unique_constraint(:handle)
    |> unique_constraint([:vcs_id, :vcs_platform])
    |> assoc_constraint(:account)
  end

  # Queries

  def find_by_repository_query(vcs_id, vcs_platform) do
    from(p in __MODULE__,
      where: p.vcs_id == ^vcs_id and p.vcs_platform == ^vcs_platform
    )
  end
end
