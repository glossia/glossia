defmodule Glossia.Sandboxes.Sandbox do
  use Glossia.Schema
  import Ecto.Changeset

  @statuses ~w(pending ready terminating terminated failed)

  @derive {
    Flop.Schema,
    filterable: [:status, :purpose, :backend],
    sortable: [:inserted_at, :status, :deadline_at],
    default_order: %{order_by: [:inserted_at], order_directions: [:desc]}
  }

  schema "sandboxes" do
    field :status, :string, default: "pending"
    field :purpose, :string, default: "manual"
    field :backend, :string, default: "flame"
    field :backend_ref, :string
    field :labels, :map, default: %{}
    field :error, :string
    field :ready_at, :utc_datetime_usec
    field :deadline_at, :utc_datetime_usec
    field :terminated_at, :utc_datetime_usec

    belongs_to :account, Glossia.Accounts.Account
    belongs_to :project, Glossia.Accounts.Project
    has_many :sessions, Glossia.Sandboxes.SandboxSession

    timestamps()
  end

  def statuses, do: @statuses

  def changeset(sandbox, attrs) do
    sandbox
    |> cast(attrs, [
      :account_id,
      :project_id,
      :status,
      :purpose,
      :backend,
      :backend_ref,
      :labels,
      :error,
      :ready_at,
      :deadline_at,
      :terminated_at
    ])
    |> validate_required([:account_id, :status, :purpose, :backend, :labels])
    |> validate_inclusion(:status, @statuses)
    |> validate_length(:purpose, min: 1, max: 100)
    |> validate_change(:labels, fn :labels, labels ->
      if is_map(labels), do: [], else: [labels: "must be a map"]
    end)
  end
end
