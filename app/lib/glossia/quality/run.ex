defmodule Glossia.Quality.Run do
  use Glossia.Schema
  import Ecto.Changeset

  @statuses ~w(pending running completed failed cancelled)

  @derive {
    Flop.Schema,
    filterable: [:status],
    sortable: [:inserted_at, :status],
    default_limit: 25,
    max_limit: 50,
    pagination_types: [:page],
    default_pagination_type: :page,
    default_order: %{order_by: [:inserted_at], order_directions: [:desc]}
  }

  schema "quality_runs" do
    field :status, :string, default: "pending"
    field :configuration, :map, default: %{}
    field :pages_count, :integer, default: 0
    field :findings_count, :integer, default: 0
    field :error, :string
    field :started_at, :utc_datetime_usec
    field :completed_at, :utc_datetime_usec

    belongs_to :account, Glossia.Accounts.Account
    belongs_to :project, Glossia.Accounts.Project
    belongs_to :triggered_by, Glossia.Accounts.User
    belongs_to :sandbox, Glossia.Sandboxes.Sandbox

    has_many :pages, Glossia.Quality.Page
    has_many :occurrences, Glossia.Quality.Occurrence
    has_many :session_events, Glossia.Quality.SessionEvent

    timestamps()
  end

  def changeset(run, attrs) do
    run
    |> cast(attrs, [
      :account_id,
      :project_id,
      :triggered_by_id,
      :sandbox_id,
      :status,
      :configuration,
      :pages_count,
      :findings_count,
      :error,
      :started_at,
      :completed_at
    ])
    |> validate_required([:account_id, :project_id, :status, :configuration])
    |> validate_inclusion(:status, @statuses)
    |> validate_number(:pages_count, greater_than_or_equal_to: 0)
    |> validate_number(:findings_count, greater_than_or_equal_to: 0)
    |> unique_constraint(:project_id, name: :quality_runs_one_active_per_project_index)
  end
end
