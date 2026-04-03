defmodule Glossia.Auditing.Sink do
  @moduledoc """
  Behaviour for recording audit events.
  """

  @callback list_events(term(), keyword()) :: [map()]
end
