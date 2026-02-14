defmodule Glossia.Accounts.VoiceOverride do
  use Glossia.Schema
  import Ecto.Changeset

  schema "voice_overrides" do
    field :locale, :string
    field :tone, :string
    field :formality, :string
    field :target_audience, :string
    field :guidelines, :string

    belongs_to :voice, Glossia.Accounts.Voice

    timestamps(updated_at: false)
  end

  def changeset(override, attrs) do
    override
    |> cast(attrs, [:locale, :tone, :formality, :target_audience, :guidelines])
    |> validate_required([:locale])
    |> validate_format(:locale, ~r/^[a-z]{2}(-[A-Za-z]{2,})?$/,
      message: "must be a valid locale like 'en', 'ja', 'es-MX'"
    )
    |> validate_inclusion(:tone, ~w(casual formal playful authoritative neutral))
    |> validate_inclusion(:formality, ~w(informal neutral formal very_formal))
    |> unique_constraint([:voice_id, :locale])
  end
end
