defmodule Glossia.Auditing.Sink do
  @moduledoc """
  Behaviour for recording audit events.
  """

  @type event :: %{
          required(:name) => String.t(),
          required(:account) => struct(),
          required(:user) => struct() | nil,
          required(:opts) => keyword()
        }

  @callback record(event()) :: :ok
  @callback list_events(term(), keyword()) :: [map()]
end
