defmodule Glossia.TranslationSessions.TranslationSession do
  use Glossia.Schema
  import Ecto.Changeset

  @derive {
    Flop.Schema,
    filterable: [:status, :outcome, :commit_sha, :commit_message, :source_language],
    sortable: [:inserted_at, :status, :outcome, :translated_content_count, :content_hit_count],
    default_order: %{order_by: [:inserted_at], order_directions: [:desc]}
  }

  @statuses ~w(pending running completed failed cancelled)
  @outcomes ~w(translated content_hit superseded cancelled failed)

  schema "translation_sessions" do
    field :commit_sha, :string
    field :commit_message, :string
    field :status, :string, default: "pending"
    field :outcome, :string
    field :translated_content_count, :integer, default: 0
    field :content_hit_count, :integer, default: 0
    field :source_language, :string
    field :target_languages, {:array, :string}, default: []
    field :summary, :string
    field :error, :string
    field :publication_branch, :string
    field :publication_commit_sha, :string
    field :pull_request_url, :string
    field :pull_request_number, :integer
    field :started_at, :utc_datetime_usec
    field :completed_at, :utc_datetime_usec

    belongs_to :account, Glossia.Accounts.Account
    belongs_to :project, Glossia.Accounts.Project
    belongs_to :continued_from_session, __MODULE__

    timestamps()
  end

  def changeset(session, attrs) do
    session
    |> cast(attrs, [
      :commit_sha,
      :commit_message,
      :status,
      :outcome,
      :translated_content_count,
      :content_hit_count,
      :source_language,
      :target_languages,
      :summary,
      :error,
      :publication_branch,
      :publication_commit_sha,
      :pull_request_url,
      :pull_request_number,
      :continued_from_session_id,
      :started_at,
      :completed_at
    ])
    |> validate_required([:status])
    |> validate_inclusion(:status, @statuses)
    |> validate_inclusion(:outcome, @outcomes)
  end
end
