defmodule Glossia.Auditing.DefaultSink do
  @moduledoc false

  @behaviour Glossia.Auditing.Sink

  alias Glossia.ClickHouseRepo
  alias Glossia.Ingestion.{Buffer, Event}

  import Ecto.Query

  require Logger

  @event_buffer Glossia.Ingestion.EventBuffer

  @impl true
  def record(%{name: name, account: account, user: user, opts: opts}) do
    buffer_opts = Event.buffer_opts()

    actor_handle = user_actor_handle(user)
    actor_email = user_actor_email(user)
    user_id = user_actor_id(user)

    row = [
      Uniq.UUID.uuid7(:raw),
      name,
      to_string(account.id),
      user_id,
      actor_handle,
      actor_email,
      opts[:resource_type] || "",
      opts[:resource_id] || "",
      opts[:resource_path] || "",
      opts[:summary] || "",
      opts[:duration_ms] || 0,
      opts[:metadata] || ""
    ]

    row_binary = Ch.RowBinary.encode_row(row, buffer_opts.encoding_types)
    Buffer.insert(@event_buffer, row_binary)

    Logger.info(fn ->
      JSON.encode!(%{
        type: "audit_event",
        name: name,
        account_id: to_string(account.id),
        user_id: if(user_id == "", do: nil, else: user_id),
        actor_handle: if(actor_handle == "", do: nil, else: actor_handle),
        actor_email: if(actor_email == "", do: nil, else: actor_email),
        resource_type: opts[:resource_type],
        resource_id: opts[:resource_id],
        resource_path: opts[:resource_path],
        summary: opts[:summary],
        duration_ms: opts[:duration_ms],
        metadata: opts[:metadata]
      })
    end)

    :ok
  end

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

  defp user_actor_id(nil), do: ""
  defp user_actor_id(%{id: id}), do: to_string(id)

  defp user_actor_handle(nil), do: ""

  defp user_actor_handle(%{account: %{handle: handle}}) when is_binary(handle),
    do: handle

  defp user_actor_handle(_user), do: ""

  defp user_actor_email(nil), do: ""
  defp user_actor_email(%{email: email}) when is_binary(email), do: email
  defp user_actor_email(_user), do: ""
end
