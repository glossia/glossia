defmodule Glossia.Foundation.Accounts.Core.Models.Account do
  @moduledoc """
  A module that represents the accounts table
  """

  # Types
  @type t :: %__MODULE__{
          handle: String.t(),
          projects: [Project.t()] | nil
        }

  # Modules
  import Ecto.Query, only: [from: 2]
  use Ecto.Schema
  import Ecto.Changeset
  alias Glossia.Foundation.Projects.Core.Models.Project

  # Schema

  schema "accounts" do
    field :handle, :string

    has_many(:projects, Project)
    timestamps()
  end

  # Changesets

  @reserved_handles [
    "docs",
    "about",
    "terms",
    "cookies",
    "blog",
    "dev",
    "security-policy",
    "changelog",
    "releases",
    "settings",
    "mission",
    "vision",
    "team",
    "organizations",
    "projects",
    "api",
    "pricing",
    "support",
    "contact",
    "status",
    "security",
    "privacy",
    "webhooks",
    "webhook",
    "builder",
    "builder-api"
  ]

  @type create_account_changeset_attrs :: %{
          handle: String.t()
        }

  @doc """

  """
  @spec changeset(account :: t(), attrs :: create_account_changeset_attrs()) :: Ecto.Changeset.t()
  def changeset(account, attrs) do
    account
    |> cast(attrs, [:handle])
    |> validate_required([:handle])
    |> validate_format(:handle, ~r/^[a-z0-9_]+$/i, message: "must be alphanumeric")
    |> validate_exclusion(:handle, @reserved_handles)
    |> validate_length(:handle, min: 3, max: 20)
    |> unique_constraint(:handle)
  end

  @doc """
  Returns a list of handles that are reserved for Glossia.
  """
  @spec reserved_handles() :: [String.t()]
  def reserved_handles do
    @reserved_handles
  end

  # Queries

  @doc """
  It returns the query to find an account by its handle.
  """
  @spec account_by_handle_query(any) :: Ecto.Query.t()
  def account_by_handle_query(handle) do
    from(a in __MODULE__, where: a.handle == ^handle)
  end
end