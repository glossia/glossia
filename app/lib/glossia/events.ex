defmodule Glossia.Events do
  @moduledoc """
  Facade for emitting imperative domain events.
  """

  alias Glossia.Events.Event

  def emit(name, account, user, opts \\ []) do
    %Event{
      name: name,
      account: account,
      user: user,
      opts: opts,
      occurred_at: DateTime.utc_now()
    }
    |> handler().handle_event()
  end

  defp handler, do: Glossia.Extensions.event_handler()
end
