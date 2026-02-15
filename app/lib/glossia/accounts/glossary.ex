defmodule Glossia.Accounts.Glossary do
  use Glossia.Schema
  import Ecto.Changeset

  @derive {
    Flop.Schema,
    filterable: [:version, :change_note],
    sortable: [:version, :inserted_at],
    default_order: %{order_by: [:version], order_directions: [:desc]}
  }

  schema "glossaries" do
    field :version, :integer
    field :change_note, :string

    belongs_to :account, Glossia.Accounts.Account
    belongs_to :created_by, Glossia.Accounts.User
    has_many :entries, Glossia.Accounts.GlossaryEntry

    timestamps(updated_at: false)
  end

  def changeset(glossary, attrs) do
    glossary
    |> cast(attrs, [:version, :change_note])
    |> validate_required([:version])
    |> unique_constraint([:account_id, :version])
  end
end
