defmodule Glossia.Events.Handler do
  @moduledoc """
  Behaviour for imperative domain event handlers and optional read models.
  """

  alias Glossia.Events.Event

  @callback handle_event(Event.t()) :: :ok
  @callback list_events(term(), keyword()) :: [map()]
end
