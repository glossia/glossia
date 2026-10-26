defmodule GlossiaEnterprise.Audit.Event do
  @moduledoc """
  ClickHouse row schema for enterprise audit events.

  This schema preserves the existing audit storage format. Domain-event
  emission and product analytics remain part of the Apache-2.0 core.
  """

  use Ecto.Schema
  use Glossia.Ingestion.Bufferable

  @primary_key false

  schema "events" do
    field :id, Ch, type: "UUID"
    field :name, Ch, type: "String"
    field :account_id, Ch, type: "String"
    field :user_id, Ch, type: "String"
    field :actor_handle, Ch, type: "String"
    field :actor_email, Ch, type: "String"
    field :resource_type, Ch, type: "LowCardinality(String)"
    field :resource_id, Ch, type: "String"
    field :resource_path, Ch, type: "String"
    field :summary, Ch, type: "String"
    field :duration_ms, Ch, type: "UInt64"
    field :metadata, Ch, type: "String"
  end
end
