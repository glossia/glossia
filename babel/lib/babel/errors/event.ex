defmodule Babel.Errors.Event do
  @moduledoc """
  A single ingested error event. In Hive these rows lived in ClickHouse
  for cheap high-cardinality analytics; Babel keeps them in Postgres for
  operational simplicity. If event volume grows past what Postgres can
  serve, revisit an OLAP store — the schema is intentionally denormalised
  so the migration path stays simple.
  """

  use Ecto.Schema

  import Ecto.Changeset

  alias Babel.Errors.Issue
  alias Babel.Organizations.Organization

  @primary_key {:event_id, :binary_id, autogenerate: false}
  @foreign_key_type :binary_id

  schema "errors_events" do
    field :fingerprint, :string
    field :timestamp, :utc_datetime_usec
    field :received_at, :utc_datetime_usec
    field :platform, :string
    field :level, :string
    field :environment, :string
    field :release, :string
    field :dist, :string
    field :server_name, :string
    field :transaction, :string
    field :logger, :string
    field :exception_type, :string
    field :exception_value, :string
    field :top_frame_function, :string
    field :top_frame_module, :string
    field :top_frame_filename, :string
    field :user_id, :string
    field :user_email, :string
    field :user_ip, :string
    field :request_url, :string
    field :request_method, :string
    field :sdk_name, :string
    field :sdk_version, :string
    field :tags, :map, default: %{}
    field :payload, :string

    belongs_to :organization, Organization, type: :id
    belongs_to :issue, Issue

    timestamps(type: :utc_datetime_usec, updated_at: false)
  end

  def changeset(event, attrs) do
    event
    |> cast(attrs, [
      :event_id,
      :organization_id,
      :issue_id,
      :fingerprint,
      :timestamp,
      :received_at,
      :platform,
      :level,
      :environment,
      :release,
      :dist,
      :server_name,
      :transaction,
      :logger,
      :exception_type,
      :exception_value,
      :top_frame_function,
      :top_frame_module,
      :top_frame_filename,
      :user_id,
      :user_email,
      :user_ip,
      :request_url,
      :request_method,
      :sdk_name,
      :sdk_version,
      :tags,
      :payload
    ])
    |> validate_required([
      :event_id,
      :organization_id,
      :issue_id,
      :fingerprint,
      :timestamp,
      :received_at
    ])
  end
end
