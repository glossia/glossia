defmodule Glossia.LinguisticReviews.Review do
  @moduledoc "A shared, source-bound linguistic decision, separate from private Toki history."
  use Glossia.Schema
  import Ecto.Changeset

  # Ecto casts many-to-many preload keys; the default Uniq binary storage
  # type would cast the PostgreSQL UUID join key to bytea.
  @primary_key {:id, Uniq.UUID, version: 7, autogenerate: true, type: :uuid}
  schema "linguistic_reviews" do
    belongs_to :translation_session, Glossia.TranslationSessions.TranslationSession
    belongs_to :answered_by, Glossia.Accounts.User
    belongs_to :resumed_session, Glossia.TranslationSessions.TranslationSession
    belongs_to :resolution_message, Glossia.Toki.Message
    has_one :conversation, Glossia.Toki.Conversation, foreign_key: :linguistic_review_id

    many_to_many :participants, Glossia.Accounts.User,
      join_through: Glossia.LinguisticReviews.Participant,
      join_keys: [linguistic_review_id: :id, user_id: :id]

    field :source_path, :string
    field :output_path, :string
    field :locale, :string
    field :fingerprint, :string
    field :reason, :string
    field :question, :string
    field :source_excerpt, :string
    field :translation_excerpt, :string
    field :status, :string, default: "open"
    field :answer, :string
    field :guidance, :string
    field :context_path, :string
    field :context_digest, :string
    field :context_targets, :map, default: %{}
    timestamps()
  end

  def answer_changeset(review, attrs) do
    review
    |> cast(attrs, [:answer, :guidance])
    |> validate_required([:answer])
    |> validate_length(:answer, max: 8_000)
    |> validate_length(:guidance, max: 8_000)
    |> validate_change(:answer, &bounded_bytes/2)
    |> validate_change(:guidance, &bounded_bytes/2)
    |> validate_change(:guidance, fn key, value ->
      if String.contains?(value, [
           "<!-- glossia:linguistic-review:",
           "<!-- /glossia:linguistic-review:"
         ]),
         do: [{key, "contains reserved review markers"}],
         else: []
    end)
  end

  defp bounded_bytes(key, value) do
    if byte_size(value) > 32_000, do: [{key, "is too long"}], else: []
  end
end
