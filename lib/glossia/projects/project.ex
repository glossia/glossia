defmodule Glossia.Projects.Project do
  alias Glossia.Accounts.Account

  @moduledoc """
  A module that represents the projects table
  """

  # Types

  @type t :: %__MODULE__{
          handle: String.t(),
          account: Account.t() | nil,
          visibility: visibility(),
          content_source_id: String.t(),
          content_source_platform: content_source_platform()
        }
  @type visibility :: :public | :private
  @type content_source_platform :: :github

  # Module dependencies

  alias Glossia.Accounts.Account
  alias Glossia.Builds.Build
  use Glossia.DatabaseSchema
  import Ecto.Changeset
  import Ecto.Query, only: [from: 2]

  # Schema

  schema "projects" do
    field :handle, :string
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
  @spec changeset(project :: any(), attrs :: map()) :: Ecto.Changeset.t()
  def changeset(project, attrs) do
    project
    |> cast(attrs, [
      :handle,
      :content_source_id,
      :content_source_platform,
      :account_id,
      :visibility
    ])
    |> validate_required(
      [
        :handle,
        :content_source_id,
        :content_source_platform,
        :account_id
      ],
      message: "This attribute is required"
    )
    |> validate_inclusion(:content_source_platform, [:github])
    |> validate_format(:handle, ~r/^[a-z0-9_]+$/i, message: "Handle must be alphanumeric")
    |> validate_length(:handle,
      min: 3,
      max: 20,
      message: "The length should be between 3 and 20 characters"
    )
    |> unique_constraint([:handle, :account_id],
      message: "There's already a project with the same handle"
    )
    |> unique_constraint([:content_source_id, :content_source_platform],
      message: "There's already a project with the same repository"
    )
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
      join: a in Account,
      on: p.account_id == a.id,
      where: p.handle == ^project and a.handle == ^owner,
      select: p
    )
  end
end
