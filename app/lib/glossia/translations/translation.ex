defmodule Glossia.Translations.Translation do
  use Glossia.Schema
  import Ecto.Changeset

  @derive {
    Flop.Schema,
    filterable: [:status, :commit_sha, :source_language],
    sortable: [:inserted_at, :status],
    default_order: %{order_by: [:inserted_at], order_directions: [:desc]}
  }

  @statuses ~w(pending running completed failed)

  schema "translations" do
    field :commit_sha, :string
    field :commit_message, :string
    field :status, :string, default: "pending"
    field :source_language, :string
    field :target_languages, {:array, :string}, default: []
    field :summary, :string
    field :error, :string
    field :sandbox_id, :string
    field :started_at, :utc_datetime_usec
    field :completed_at, :utc_datetime_usec

    belongs_to :account, Glossia.Accounts.Account
    belongs_to :project, Glossia.Accounts.Project

    timestamps()
  end

  def changeset(translation, attrs) do
    translation
    |> cast(attrs, [
      :commit_sha,
      :commit_message,
      :status,
      :source_language,
      :target_languages,
      :summary,
      :error,
      :started_at,
      :completed_at
    ])
    |> validate_required([:status])
    |> validate_inclusion(:status, @statuses)
  end
end
