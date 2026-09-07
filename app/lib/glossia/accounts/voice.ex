defmodule Glossia.Accounts.Voice do
  use Glossia.Schema
  import Ecto.Changeset

  @target_audience_limit 500
  @guidelines_limit 4_000
  @description_limit 1_200
  @cultural_note_limit 1_800

  @derive {
    Flop.Schema,
    filterable: [:version, :tone, :formality],
    sortable: [:version, :inserted_at],
    default_order: %{order_by: [:version], order_directions: [:desc]}
  }

  schema "voices" do
    field :version, :integer
    field :tone, :string
    field :formality, :string
    field :target_audience, :string
    field :guidelines, :string
    field :description, :string
    field :target_countries, {:array, :string}, default: []
    field :cultural_notes, :map, default: %{}

    belongs_to :account, Glossia.Accounts.Account
    belongs_to :created_by, Glossia.Accounts.User
    has_many :overrides, Glossia.Accounts.VoiceOverride

    timestamps(updated_at: false)
  end

  @doc false
  def target_audience_limit, do: @target_audience_limit

  @doc false
  def guidelines_limit, do: @guidelines_limit

  @doc false
  def description_limit, do: @description_limit

  @doc false
  def cultural_note_limit, do: @cultural_note_limit

  def changeset(voice, attrs) do
    voice
    |> cast(attrs, [
      :tone,
      :formality,
      :target_audience,
      :guidelines,
      :description,
      :target_countries,
      :cultural_notes,
      :version
    ])
    |> validate_required([:version])
    |> validate_inclusion(:tone, ~w(casual formal playful authoritative neutral))
    |> validate_inclusion(:formality, ~w(informal neutral formal very_formal))
    |> validate_length(:target_audience, max: @target_audience_limit, count: :bytes)
    |> validate_length(:guidelines, max: @guidelines_limit, count: :bytes)
    |> validate_length(:description, max: @description_limit, count: :bytes)
    |> validate_cultural_notes()
    |> unique_constraint([:account_id, :version])
  end

  defp validate_cultural_notes(changeset) do
    validate_change(changeset, :cultural_notes, fn :cultural_notes, notes ->
      if Enum.all?(notes, fn {_country, note} ->
           is_binary(note) and byte_size(note) <= @cultural_note_limit
         end) do
        []
      else
        [
          cultural_notes:
            "must map countries to text no longer than #{@cultural_note_limit} bytes"
        ]
      end
    end)
  end
end
