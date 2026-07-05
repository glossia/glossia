defmodule Glossia.Sandboxes.SandboxSession do
  use Glossia.Schema
  import Ecto.Changeset

  @statuses ~w(open closed)

  schema "sandbox_sessions" do
    field :status, :string, default: "open"
    field :opened_at, :utc_datetime_usec
    field :closed_at, :utc_datetime_usec
    field :close_reason, :string

    belongs_to :sandbox, Glossia.Sandboxes.Sandbox
    belongs_to :account, Glossia.Accounts.Account
    belongs_to :project, Glossia.Accounts.Project

    timestamps()
  end

  def changeset(session, attrs) do
    session
    |> cast(attrs, [
      :sandbox_id,
      :account_id,
      :project_id,
      :status,
      :opened_at,
      :closed_at,
      :close_reason
    ])
    |> validate_required([:sandbox_id, :account_id, :status, :opened_at])
    |> validate_inclusion(:status, @statuses)
  end
end
