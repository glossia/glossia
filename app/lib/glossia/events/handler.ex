defmodule Glossia.Events.Handler do
  @moduledoc """
  Behaviour for imperative domain event handlers.
  """

  alias Glossia.Events.Event

  @callback handle_event(Event.t()) :: :ok
end
