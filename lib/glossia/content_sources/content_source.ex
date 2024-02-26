defmodule Glossia.ContentSources.ContentSource do
  alias Glossia.Accounts.Account

  @moduledoc ~S"""
  A module that represents a source whose content changes over time.
  """

  # Types

  @type t :: %__MODULE__{
          account: Account.t() | nil,
          id_in_content_platform: String.t(),
          content_platform: content_platform()
        }
  @type content_platform :: :github

  # Module dependencies

  alias Glossia.Accounts.Account
  use Glossia.DatabaseSchema
  import Ecto.Changeset
  import Ecto.Query, only: [from: 2]

  # Schema

  schema "content_sources" do
    field :handle, :string
    field :id_in_content_platform, :string
    field :content_platform, Ecto.Enum, values: [{:github, 1}]
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
      :id_in_content_platform,
      :content_platform,
      :account_id
    ])
    |> validate_required(
      [
        :id_in_content_platform,
        :content_platform,
        :account_id
      ],
      message: "This attribute is required"
    )
    |> validate_inclusion(:content_platform, [:github])
    |> unique_constraint([:id_in_content_platform, :content_platform],
      message: "There's already a content source with the same platform and id."
    )
    |> assoc_constraint(:account)
  end

  # Queries

  def find_content_source(%{
        content_platform: content_platform,
        id_in_content_platform: id_in_content_platform
      }) do
    from(p in __MODULE__,
      where:
        p.id_in_content_platform == ^id_in_content_platform and
          p.content_platform == ^content_platform
    )
  end
end
