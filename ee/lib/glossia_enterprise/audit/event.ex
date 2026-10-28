defmodule GlossiaEnterprise.Audit.Event do
  @moduledoc """
  Durable account-scoped audit records with actor snapshots.

  No foreign keys remove records when an actor or resource is deleted.
  Arbitrary domain-event metadata and authentication credentials are not stored.
  """

  use Glossia.Schema

  schema "audit_events" do
    field :name, :string
    field :account_id, Uniq.UUID
    field :user_id, Uniq.UUID
    field :actor_handle, :string
    field :actor_email, :string
    field :resource_type, :string
    field :resource_id, :string
    field :summary, :string
    field :metadata, :map, default: %{}
    field :occurred_at, :utc_datetime_usec
  end
end
