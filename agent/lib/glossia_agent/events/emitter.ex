defmodule GlossiaAgent.Events.Emitter do
  @moduledoc """
  Behaviour for event emission during agent workflows.

  Implementations:
  - `GlossiaAgent.Events.LocalEmitter` -- sends messages to a PID (local mode)
  - `GlossiaAgent.Events.ChannelEmitter` -- pushes to Phoenix channel via WebSocket (remote mode)
  """

  @callback emit(emitter :: term(), type :: String.t(), content :: String.t()) :: :ok
  @callback complete(emitter :: term()) :: :ok
  @callback fail(emitter :: term(), reason :: String.t()) :: :ok

  @doc "Emit an event via the given emitter."
  @spec emit(term(), String.t(), String.t()) :: :ok
  def emit(%{module: mod} = emitter, type, content), do: mod.emit(emitter, type, content)

  @doc "Signal successful completion."
  @spec complete(term()) :: :ok
  def complete(%{module: mod} = emitter), do: mod.complete(emitter)

  @doc "Signal failure with a reason."
  @spec fail(term(), String.t()) :: :ok
  def fail(%{module: mod} = emitter, reason), do: mod.fail(emitter, reason)
end
