defmodule Glossia.Events do
  @moduledoc """
  Facade for emitting imperative domain events.
  """

  alias Glossia.Events.Event

  require Logger

  def emit(name, account, user, opts \\ []) do
    event = %Event{
      name: name,
      account: account,
      user: user,
      opts: opts,
      occurred_at: DateTime.utc_now()
    }

    Logger.info("Domain event emitted",
      event_name: name,
      account_id: resource_id(account),
      user_id: resource_id(user),
      resource_type: Keyword.get(opts, :resource_type),
      resource_id: Keyword.get(opts, :resource_id)
    )

    handler().handle_event(event)
  end

  defp handler, do: Glossia.Extensions.event_handler()

  defp resource_id(nil), do: nil
  defp resource_id(%{id: id}), do: id
  defp resource_id(_resource), do: nil
end
