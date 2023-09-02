defmodule Glossia.Foundation.Projects.Core.Project do
  use Boundary

  @moduledoc """
  A module that represents the projects table
  """

  # Types

  @type t :: %__MODULE__{
          handle: String.t(),
          account: Account.t() | nil,
          type: type(),
          visibility: visibility(),
          content_source_id: String.t(),
          content_source_platform: Glossia.Foundation.ContentSources.t()
        }
  @type visibility :: :public | :private
  @type type :: :git

  # Module dependencies

  alias Glossia.Foundation.Accounts.Core.Account
  alias Glossia.Foundation.Builds.Core.Build
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query, only: [from: 2]

  # Schema

  schema "projects" do
    field :handle, :string
    field :type, Ecto.Enum, values: [{:git, 1}], default: :git
    field :content_source_id, :string
    field :content_source_platform, Ecto.Enum, values: [{:github, 1}]
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
          content_source_id: String.t(),
          content_source_platform: Glossia.Foundation.ContentSources.t(),
          account_id: integer()
        }
  @spec changeset(project :: t(), attrs :: changeset_attrs()) :: Ecto.Changeset.t()
  def changeset(project, attrs) do
    project
    |> cast(attrs, [
      :handle,
      :content_source_id,
      :content_source_platform,
      :account_id,
      :visibility,
      :type
    ])
    |> validate_required([
      :handle,
      :content_source_id,
      :content_source_platform,
      :account_id,
      :type
    ])
    |> validate_inclusion(:content_source_platform, [:github])
    |> validate_inclusion(:type, [:git])
    |> validate_format(:handle, ~r/^[a-z0-9_]+$/i, message: "must be alphanumeric")
    |> validate_length(:handle, min: 3, max: 20)
    |> unique_constraint(:handle)
    |> unique_constraint([:content_source_id, :content_source_platform])
    |> assoc_constraint(:account)
  end

  # Queries

  def find_project_by_repository_query(%{
        content_source_platform: content_source_platform,
        content_source_id: content_source_id
      }) do
    from(p in __MODULE__,
      where:
        p.content_source_id == ^content_source_id and
          p.content_source_platform == ^content_source_platform
    )
  end

  @doc """
  It returns the query to find a project by its owner and project handle.
  """
  @spec find_project_by_owner_and_project_handle_query(owner :: String.t(), project :: String.t()) ::
          Ecto.Query.t()
  def find_project_by_owner_and_project_handle_query(owner, project) do
    from(p in __MODULE__,
      join: a in assoc(p, :account),
      where: p.handle == ^project and a.handle == ^owner,
      select: p
    )
  end
end
