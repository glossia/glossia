defmodule Glossia.Accounts.Voice do
  use Glossia.Schema
  import Ecto.Changeset

  @derive {
    Flop.Schema,
    filterable: [:version, :tone, :formality, :change_note],
    sortable: [:version, :inserted_at],
    default_order: %{order_by: [:version], order_directions: [:desc]}
  }

  schema "voices" do
    field :version, :integer
    field :tone, :string
    field :formality, :string
    field :target_audience, :string
    field :guidelines, :string
    field :change_note, :string

    belongs_to :account, Glossia.Accounts.Account
    belongs_to :created_by, Glossia.Accounts.User
    has_many :overrides, Glossia.Accounts.VoiceOverride

    timestamps(updated_at: false)
  end

  def changeset(voice, attrs) do
    voice
    |> cast(attrs, [:tone, :formality, :target_audience, :guidelines, :change_note, :version])
    |> validate_required([:version])
    |> validate_inclusion(:tone, ~w(casual formal playful authoritative neutral))
    |> validate_inclusion(:formality, ~w(informal neutral formal very_formal))
    |> unique_constraint([:account_id, :version])
  end
end
