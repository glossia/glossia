defmodule Glossia.ContentSources.ContentSource do
  alias Glossia.Accounts.Account
  alias Glossia.ContentSources.ContentSource

  @moduledoc ~S"""
  A module that represents a source whose content changes over time.
  """

  # Types

  @type t :: %__MODULE__{
          account: Account.t() | nil,
          id_in_platform: String.t(),
          platform: platform()
        }
  @type platform :: :github

  # Module dependencies

  alias Glossia.Accounts.Account
  use Glossia.DatabaseSchema
  import Ecto.Changeset
  import Ecto.Query, only: [from: 2]

  # Schema

  schema "content_sources" do
    field :id_in_platform, :string
    field :platform, Ecto.Enum, values: [{:github, 1}]
    belongs_to :account, Account, on_replace: :raise

    timestamps()
  end

  # Changesets

  @doc ~S"""
  It returns the base `Ecto.Changeset` to create and update content sources.
  """
  @spec changeset(content_source :: any(), attrs :: map()) :: Ecto.Changeset.t()
  def changeset(content_source, attrs) do
    content_source
    |> cast(attrs, [
      :id_in_platform,
      :platform,
      :account_id
    ])
    |> validate_required(
      [
        :id_in_platform,
        :platform,
        :account_id
      ],
      message: "This attribute is required"
    )
    |> validate_inclusion(:platform, [:github])
    |> unique_constraint([:id_in_platform, :platform],
      message: "There's already a content source with the same platform and id."
    )
    |> assoc_constraint(:account)
  end

  # Queries

  @doc """
  Given a platform and an id inside the platform, it returns a content source.

  ## Examples

      iex> Glossia.ContentSources.ContentSource.find_content_source(%{platform: :github, id_in_platform: "org/repo"}) |> Repo.one()
  """
  @spec find_content_source_query(%{
          id_in_platform: any(),
          platform: ContentSource.platform()
        }) :: Ecto.Query.t()
  def find_content_source_query(%{
        platform: platform,
        id_in_platform: id_in_platform
      }) do
    from(p in __MODULE__,
      where:
        p.id_in_platform == ^id_in_platform and
          p.platform == ^platform
    )
  end
end
