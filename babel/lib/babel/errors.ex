defmodule Babel.Errors do
  @moduledoc """
  Error tracking for Babel: a Sentry-compatible ingest endpoint plus
  the Postgres storage that backs it.

  Events land as Sentry envelopes on `POST /api/:project_id/envelope/`,
  are parsed into `Babel.Errors.SentryEvent`, grouped into
  `Babel.Errors.Issue` records by fingerprint, and appended as rows to
  the `errors_events` table.

  This surface is private by design. Errors frequently carry sensitive
  data (user identifiers, request payloads, stack-trace context), so
  every dashboard, feed, and MCP tool that reads issues or events
  requires an authenticated organization member. The ingest endpoint
  itself is public but authenticated by DSN public key.

  ## Acceptance semantics

  A `200` on the envelope endpoint means "accepted for ingest". Events
  are parsed inline, the event row is written to Postgres synchronously,
  and the issue upsert is cast to `Babel.Errors.IssueCoalescer` — the
  issue row and its counter are eventually consistent within the
  coalescer's flush window (default 5 s). Sentry SDKs cache and retry
  envelope submission on 5xx, so we never return 5xx after DSN
  validation and rely on the SDK's retry loop for durability.

  The issue id is a deterministic UUIDv5 derived from
  `(organization_id, fingerprint)` — see
  `Babel.Errors.Issue.deterministic_id/2` — so the event row can name
  its owning issue in memory without waiting on Postgres.

  TODO: port `Babel.Errors.LoggerHandler` so Babel's own logs feed
  back into the same store (self-monitoring). Skipped in this layer to
  keep the scope tight.
  """

  import Ecto.Query

  require Logger

  alias Babel.Errors.Envelope
  alias Babel.Errors.Event
  alias Babel.Errors.Fingerprint
  alias Babel.Errors.Issue
  alias Babel.Errors.IssueCoalescer
  alias Babel.Errors.Key
  alias Babel.Errors.SentryEvent
  alias Babel.Repo

  ## Ingestion

  @doc """
  Ingests a raw Sentry envelope body for an organization. Parses each
  event item and hands it to `record_event/2`. Malformed envelopes and
  malformed items are dropped with a warning — never propagated as
  errors to the caller — so the ingest endpoint can always return 200
  once the DSN has been validated (Sentry SDKs never retry on 200 but
  do retry on 5xx, and a stuck malformed envelope would loop forever).
  """
  def ingest_envelope(organization_id, body)
      when is_integer(organization_id) and is_binary(body) do
    case Envelope.parse(body) do
      {:ok, envelope} ->
        envelope.items
        |> Enum.filter(&(&1.type == "event"))
        |> Enum.each(&ingest_event_item(organization_id, &1))

        :ok

      {:error, reason} ->
        Logger.warning("errors: dropping malformed envelope: #{inspect(reason)}")
        :ok
    end
  end

  defp ingest_event_item(organization_id, item) do
    with {:ok, decoded} <- Jason.decode(item.payload),
         event = SentryEvent.parse(decoded),
         :ok <- record_event(organization_id, event) do
      :ok
    else
      {:error, %Jason.DecodeError{}} ->
        # Malformed SDK input. Not our fault, not worth alerting on.
        :ok

      {:error, reason} ->
        Logger.warning("errors: dropping event: #{inspect(reason)}")
        :ok
    end
  end

  @doc """
  Records a parsed Sentry event against an organization. Writes the
  event row synchronously to Postgres and casts the issue upsert to
  `Babel.Errors.IssueCoalescer` for batched grouping. Returns after
  the event insert; the issue row appears within the coalescer's
  flush window.
  """
  def record_event(organization_id, %SentryEvent{} = event)
      when is_integer(organization_id) do
    fingerprint = Fingerprint.compute(event)
    issue_id = Issue.deterministic_id(organization_id, fingerprint)

    # Ensure the issue row exists before inserting the event —
    # `errors_events.issue_id` has a foreign key on `errors_issues.id`,
    # and the coalescer's issue upsert is asynchronous. The insert
    # here is a cheap `INSERT ... ON CONFLICT DO NOTHING` keyed on the
    # deterministic id, so a repeated fingerprint costs one no-op
    # round-trip; the coalescer still owns the counter/timestamp
    # rollups on its flush interval.
    :ok = ensure_issue_row(organization_id, fingerprint, event, issue_id)

    attrs = build_event_attrs(organization_id, issue_id, event, fingerprint)
    changeset = Event.changeset(%Event{}, attrs)

    case Repo.insert(changeset) do
      {:ok, _event} ->
        :ok = IssueCoalescer.observe(IssueCoalescer, organization_id, fingerprint, event)
        :ok

      {:error, changeset} ->
        {:error, changeset}
    end
  rescue
    error -> {:error, error}
  end

  defp ensure_issue_row(organization_id, fingerprint, %SentryEvent{} = event, issue_id) do
    ts = event_timestamp(event)
    now = DateTime.utc_now() |> DateTime.truncate(:second)

    row = %{
      id: issue_id,
      organization_id: organization_id,
      fingerprint: fingerprint,
      title: SentryEvent.title(event) |> truncate(500),
      culprit: SentryEvent.culprit(event) |> truncate(500),
      level: String.to_atom(event.level),
      platform: event.platform,
      status: :unresolved,
      first_seen: ts,
      last_seen: ts,
      event_count: 0,
      resolved_at: nil,
      inserted_at: now,
      updated_at: now
    }

    Repo.insert_all(Issue, [row],
      on_conflict: :nothing,
      conflict_target: [:organization_id, :fingerprint]
    )

    :ok
  end

  defp event_timestamp(%SentryEvent{timestamp: %DateTime{} = ts}), do: force_usec(ts)
  defp event_timestamp(_), do: DateTime.utc_now() |> force_usec()

  defp force_usec(%DateTime{microsecond: {_, 6}} = dt), do: dt

  defp force_usec(%DateTime{microsecond: {value, _}} = dt),
    do: %{dt | microsecond: {value, 6}}

  defp truncate(nil, _), do: nil
  defp truncate(bin, max) when is_binary(bin), do: String.slice(bin, 0, max)

  # Builds the Postgres event row attrs. Kept separate so its
  # cyclomatic complexity — one branch per string-defaulted column —
  # doesn't dominate the outer function.
  defp build_event_attrs(organization_id, issue_id, event, fingerprint) do
    %{}
    |> Map.merge(core_columns(organization_id, issue_id, event, fingerprint))
    |> Map.merge(event_scalar_columns(event))
    |> Map.merge(frame_columns(event.top_frame))
    |> Map.merge(actor_columns(event))
    |> Map.merge(sdk_columns(event))
    |> Map.put(:tags, event.tags)
    |> Map.put(:payload, Jason.encode!(event.payload))
  end

  defp core_columns(organization_id, issue_id, event, fingerprint) do
    %{
      event_id: to_uuid(event.event_id),
      organization_id: organization_id,
      issue_id: issue_id,
      fingerprint: fingerprint,
      timestamp: DateTime.truncate(event.timestamp, :microsecond),
      received_at: DateTime.utc_now() |> DateTime.truncate(:microsecond)
    }
  end

  defp event_scalar_columns(event) do
    %{
      platform: default(event.platform, "other"),
      level: default(event.level, "error"),
      environment: default(event.environment, "production"),
      release: default(event.release, ""),
      dist: default(event.dist, ""),
      server_name: default(event.server_name, ""),
      transaction: default(event.transaction, ""),
      logger: default(event.logger, ""),
      exception_type: default(event.exception_type, ""),
      exception_value: default(event.exception_value, "")
    }
  end

  defp frame_columns(frame) do
    %{
      top_frame_function: frame_field(frame, "function"),
      top_frame_module: frame_field(frame, "module"),
      top_frame_filename: frame_field(frame, "filename")
    }
  end

  defp actor_columns(event) do
    %{
      user_id: default(event.user.id, ""),
      user_email: default(event.user.email, ""),
      user_ip: default(event.user.ip_address, ""),
      request_url: default(event.request.url, ""),
      request_method: default(event.request.method, "")
    }
  end

  defp sdk_columns(event) do
    %{
      sdk_name: default(event.sdk_name, ""),
      sdk_version: default(event.sdk_version, "")
    }
  end

  defp default(nil, fallback), do: fallback
  defp default(value, _fallback), do: value

  defp frame_field(nil, _), do: ""
  defp frame_field(frame, key) when is_map(frame), do: to_string(frame[key] || "")

  defp to_uuid(event_id) when is_binary(event_id) and byte_size(event_id) == 32 do
    <<a::binary-size(8), b::binary-size(4), c::binary-size(4), d::binary-size(4),
      e::binary-size(12)>> = event_id

    "#{a}-#{b}-#{c}-#{d}-#{e}"
  end

  defp to_uuid(_), do: Ecto.UUID.generate()

  ## Issue queries

  @doc """
  Paginated issue list. Options:

    * `:status` — `:unresolved`, `:resolved`, `:ignored`, or `nil` for all.
    * `:search` — substring against title/culprit.
    * `:from`, `:to` — timeframe on `last_seen`.
    * `:sort` — `:last_seen` (default), `:first_seen`, `:event_count`, `:level`.
    * `:direction` — `:asc` or `:desc` (default).
    * `:page` — 1-indexed.
    * `:page_size` — default 25.

  Returns `{issues, meta}` where meta includes `current_page`,
  `total_pages`, `total_count`, `has_previous_page?`, `has_next_page?`.
  """
  def list_issues(organization_id, opts \\ []) when is_integer(organization_id) do
    page_size = opts |> Keyword.get(:page_size, 25) |> max(1)
    page = opts |> Keyword.get(:page, 1) |> max(1)
    offset = (page - 1) * page_size

    base =
      Issue
      |> where([issue], issue.organization_id == ^organization_id)
      |> filter_status(opts[:status])
      |> filter_search(opts[:search])
      |> filter_from(opts[:from])
      |> filter_to(opts[:to])

    total = base |> exclude(:preload) |> Repo.aggregate(:count, :id)

    issues =
      base
      |> apply_sort(opts[:sort] || :last_seen, opts[:direction] || :desc)
      |> limit(^page_size)
      |> offset(^offset)
      |> Repo.all()

    meta = %{
      current_page: page,
      page_size: page_size,
      total_count: total,
      total_pages: max(1, div(total + page_size - 1, page_size)),
      has_previous_page?: page > 1,
      has_next_page?: page * page_size < total
    }

    {issues, meta}
  end

  @doc """
  Fetches an issue scoped to an organization. Returns `{:error, :not_found}`
  when the id does not exist or belongs to another organization.
  """
  def get_issue(organization_id, id) when is_integer(organization_id) and is_binary(id) do
    case Repo.get(Issue, id) do
      %Issue{organization_id: ^organization_id} = issue -> {:ok, issue}
      _ -> {:error, :not_found}
    end
  rescue
    Ecto.Query.CastError -> {:error, :not_found}
  end

  ## Issue state transitions

  def resolve_issue(%Issue{} = issue), do: transition(issue, :resolved)
  def unresolve_issue(%Issue{} = issue), do: transition(issue, :unresolved)
  def ignore_issue(%Issue{} = issue), do: transition(issue, :ignored)

  defp transition(%Issue{} = issue, status) do
    issue
    |> Issue.status_changeset(status)
    |> Repo.update()
  end

  ## Event queries

  @doc """
  Most recent events for an issue, newest first. Options:

    * `:limit` — default 25
    * `:from`, `:to` — timeframe on `timestamp`
  """
  def list_events_for_issue(organization_id, issue_id, opts \\ [])
      when is_integer(organization_id) and is_binary(issue_id) do
    limit_value = Keyword.get(opts, :limit, 25)

    Event
    |> where([event], event.organization_id == ^organization_id and event.issue_id == ^issue_id)
    |> filter_event_from(opts[:from])
    |> filter_event_to(opts[:to])
    |> order_by([event], desc: event.timestamp)
    |> limit(^limit_value)
    |> Repo.all()
  end

  @doc """
  Fetches a single event under an issue. Accepts the event_id either
  in canonical UUID form or as the 32-character hex string SDKs emit.
  """
  def get_event(organization_id, issue_id, event_id)
      when is_integer(organization_id) and is_binary(issue_id) and is_binary(event_id) do
    canonical = canonical_event_id(event_id)

    Event
    |> where(
      [event],
      event.organization_id == ^organization_id and event.issue_id == ^issue_id and
        event.event_id == ^canonical
    )
    |> Repo.one()
    |> case do
      nil -> {:error, :not_found}
      %Event{} = event -> {:ok, event}
    end
  rescue
    Ecto.Query.CastError -> {:error, :not_found}
  end

  ## Key (DSN) management
  #
  # A key's `public_key` is what SDKs put in the DSN and send in the
  # `X-Sentry-Auth` header. `dsn_project_id` is the numeric segment in
  # the DSN URL path. Every organization can hold multiple keys; the
  # oldest one is treated as the primary.

  @doc """
  Lists keys for an organization, oldest first.
  """
  def list_keys(organization_id) when is_integer(organization_id) do
    Key
    |> where([key], key.organization_id == ^organization_id)
    |> order_by([key], asc: key.inserted_at)
    |> Repo.all()
  end

  @doc """
  Provisions a default key for the organization if none exists.
  Returns `:ok` in every branch so callers can chain without a case.
  """
  def ensure_default_key(organization_id) when is_integer(organization_id) do
    case list_keys(organization_id) do
      [] ->
        case create_key(organization_id, %{"name" => "default"}) do
          {:ok, _key} -> :ok
          {:error, _} -> :ok
        end

      _keys ->
        :ok
    end
  rescue
    _ -> :ok
  end

  @doc """
  Returns the primary (oldest) key for an organization, provisioning a
  default one lazily when missing so the dashboard can always render a
  copyable DSN.
  """
  def primary_key(organization_id) when is_integer(organization_id) do
    case list_keys(organization_id) do
      [key | _] ->
        key

      [] ->
        ensure_default_key(organization_id)

        case list_keys(organization_id) do
          [key | _] -> key
          [] -> nil
        end
    end
  end

  def create_key(organization_id, attrs \\ %{}) when is_integer(organization_id) do
    attrs =
      attrs
      |> Map.new(fn {k, v} -> {to_string(k), v} end)
      |> Map.put("organization_id", organization_id)
      |> Map.put_new("public_key", Key.generate_key())
      |> Map.put_new("secret_key", Key.generate_key())
      |> Map.put_new("name", "default")

    %Key{}
    |> Key.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Rotates the primary key: deletes every existing key for the
  organization and mints a fresh one. Called when an operator
  suspects a DSN has leaked.
  """
  def rotate_key(organization_id) when is_integer(organization_id) do
    Repo.transaction(fn ->
      {_deleted, _} =
        Repo.delete_all(from(k in Key, where: k.organization_id == ^organization_id))

      case create_key(organization_id, %{"name" => "default"}) do
        {:ok, key} -> key
        {:error, changeset} -> Repo.rollback(changeset)
      end
    end)
  end

  def delete_key(%Key{} = key), do: Repo.delete(key)

  @doc """
  Finds a key by its `public_key`. Used by the envelope ingestion
  endpoint to authenticate the request against a DSN.
  """
  def find_key_by_public(public_key) when is_binary(public_key) do
    case Repo.get_by(Key, public_key: public_key) do
      nil -> {:error, :not_found}
      %Key{} = key -> {:ok, key}
    end
  end

  @doc """
  Records that a key was used to ingest an event. Idempotent, cheap;
  called on the hot path so failures are swallowed.
  """
  def touch_key(%Key{id: id}) do
    now = DateTime.utc_now()

    Key
    |> where([k], k.id == ^id)
    |> Repo.update_all(set: [last_used_at: now])

    :ok
  rescue
    _ -> :ok
  end

  def touch_key(_), do: :ok

  ## Serialization for MCP / API

  @doc """
  Serializes an issue for JSON responses (API + MCP).
  """
  def serialize_issue(%Issue{} = issue, endpoint_url \\ nil) do
    url =
      case endpoint_url do
        nil -> nil
        base -> String.trim_trailing(base, "/") <> "/errors/#{issue.id}"
      end

    %{
      id: issue.id,
      url: url,
      organization_id: issue.organization_id,
      fingerprint: issue.fingerprint,
      title: issue.title,
      culprit: issue.culprit,
      level: to_string(issue.level),
      platform: issue.platform,
      status: to_string(issue.status),
      event_count: issue.event_count,
      first_seen: issue.first_seen && DateTime.to_iso8601(issue.first_seen),
      last_seen: issue.last_seen && DateTime.to_iso8601(issue.last_seen),
      resolved_at: issue.resolved_at && DateTime.to_iso8601(issue.resolved_at)
    }
  end

  @doc """
  Serializes a key. `endpoint_url` is the host used to render the DSN.
  """
  def serialize_key(%Key{} = key, endpoint_url) do
    %{
      id: key.id,
      organization_id: key.organization_id,
      public_key: key.public_key,
      name: key.name,
      dsn: Key.dsn(key, endpoint_url),
      last_used_at: key.last_used_at && DateTime.to_iso8601(key.last_used_at),
      inserted_at: key.inserted_at && DateTime.to_iso8601(key.inserted_at)
    }
  end

  ## Query helpers

  defp filter_status(query, nil), do: query
  defp filter_status(query, status), do: where(query, [issue], issue.status == ^status)

  defp filter_search(query, nil), do: query
  defp filter_search(query, ""), do: query

  defp filter_search(query, term) when is_binary(term) do
    like = "%#{String.replace(term, "%", "\\%")}%"
    where(query, [issue], ilike(issue.title, ^like) or ilike(issue.culprit, ^like))
  end

  defp filter_from(query, nil), do: query

  defp filter_from(query, %DateTime{} = from),
    do: where(query, [issue], issue.last_seen >= ^from)

  defp filter_to(query, nil), do: query
  defp filter_to(query, %DateTime{} = to), do: where(query, [issue], issue.last_seen <= ^to)

  defp filter_event_from(query, nil), do: query

  defp filter_event_from(query, %DateTime{} = from),
    do: where(query, [event], event.timestamp >= ^from)

  defp filter_event_to(query, nil), do: query

  defp filter_event_to(query, %DateTime{} = to),
    do: where(query, [event], event.timestamp <= ^to)

  defp apply_sort(query, :last_seen, :desc),
    do: order_by(query, [issue], desc: issue.last_seen, desc: issue.id)

  defp apply_sort(query, :last_seen, :asc),
    do: order_by(query, [issue], asc: issue.last_seen, asc: issue.id)

  defp apply_sort(query, :first_seen, :desc),
    do: order_by(query, [issue], desc: issue.first_seen, desc: issue.id)

  defp apply_sort(query, :first_seen, :asc),
    do: order_by(query, [issue], asc: issue.first_seen, asc: issue.id)

  defp apply_sort(query, :event_count, :desc),
    do: order_by(query, [issue], desc: issue.event_count, desc: issue.id)

  defp apply_sort(query, :event_count, :asc),
    do: order_by(query, [issue], asc: issue.event_count, asc: issue.id)

  defp apply_sort(query, :level, :desc),
    do: order_by(query, [issue], desc: issue.level, desc: issue.id)

  defp apply_sort(query, :level, :asc),
    do: order_by(query, [issue], asc: issue.level, asc: issue.id)

  defp apply_sort(query, _sort, _dir),
    do: order_by(query, [issue], desc: issue.last_seen, desc: issue.id)

  defp canonical_event_id(
         <<a::binary-size(8), ?-, b::binary-size(4), ?-, c::binary-size(4), ?-, d::binary-size(4),
           ?-, e::binary-size(12)>> = uuid
       )
       when byte_size(uuid) == 36,
       do: "#{a}-#{b}-#{c}-#{d}-#{e}"

  defp canonical_event_id(hex) when is_binary(hex) and byte_size(hex) == 32 do
    <<a::binary-size(8), b::binary-size(4), c::binary-size(4), d::binary-size(4),
      e::binary-size(12)>> = hex

    "#{a}-#{b}-#{c}-#{d}-#{e}"
  end

  defp canonical_event_id(other), do: other
end
