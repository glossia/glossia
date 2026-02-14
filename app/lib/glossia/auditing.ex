defmodule Glossia.Auditing do
  @moduledoc """
  Context for recording and querying audit events.

  Events are buffered and written to ClickHouse asynchronously via
  the Ingestion.Buffer GenServer.
  """

  alias Glossia.Ingestion.{Buffer, Event}
  alias Glossia.ClickHouseRepo

  import Ecto.Query

  @event_buffer Glossia.Ingestion.EventBuffer

  @doc """
  Records an audit event asynchronously via the buffer.

  ## Parameters

    - `name` - event name, e.g. `"voice.created"`
    - `account` - the Account struct
    - `user` - the User struct (actor) with `:account` preloaded, or `nil`
    - `opts` - keyword list:
      - `:resource_type` - e.g. `"voice"`
      - `:resource_id` - resource identifier
      - `:resource_path` - clickable URL path
      - `:summary` - human-readable description
      - `:duration_ms` - optional duration in milliseconds
      - `:metadata` - optional JSON string
  """
  def record(name, account, user, opts \\ []) do
    buffer_opts = Event.buffer_opts()

    row = [
      Uniq.UUID.uuid7(:raw),
      name,
      to_string(account.id),
      if(user, do: to_string(user.id), else: ""),
      if(user, do: user.account.handle || "", else: ""),
      if(user, do: user.email || "", else: ""),
      opts[:resource_type] || "",
      opts[:resource_id] || "",
      opts[:resource_path] || "",
      opts[:summary] || "",
      opts[:duration_ms] || 0,
      opts[:metadata] || ""
    ]

    row_binary = Ch.RowBinary.encode_row(row, buffer_opts.encoding_types)
    Buffer.insert(@event_buffer, row_binary)
  end

  @doc """
  Lists recent audit events for an account, ordered by most recent first.
  """
  def list_events(account_id, opts \\ []) do
    limit = Keyword.get(opts, :limit, 50)
    offset = Keyword.get(opts, :offset, 0)

    from(e in "events",
      where: e.account_id == ^to_string(account_id),
      order_by: [desc: e.inserted_at],
      limit: ^limit,
      offset: ^offset,
      select: %{
        id: e.id,
        name: e.name,
        actor_handle: e.actor_handle,
        actor_email: e.actor_email,
        resource_type: e.resource_type,
        resource_path: e.resource_path,
        summary: e.summary,
        inserted_at: e.inserted_at
      }
    )
    |> ClickHouseRepo.all()
  end
end
