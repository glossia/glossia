defmodule GlossiaAgent.Events.LocalEmitter do
  @moduledoc """
  Event emitter for local mode.
  Sends messages to a receiver PID, allowing the Phoenix server
  to track agent progress via standard Elixir message passing.
  """

  @behaviour GlossiaAgent.Events.Emitter

  defstruct [:receiver, :module, seq: 0]

  @type t :: %__MODULE__{
          receiver: pid(),
          module: module(),
          seq: non_neg_integer()
        }

  @doc "Create a new local emitter that sends events to the given PID."
  @spec new(pid()) :: t()
  def new(receiver) when is_pid(receiver) do
    %__MODULE__{receiver: receiver, module: __MODULE__}
  end

  @impl true
  def emit(%__MODULE__{receiver: receiver, seq: seq} = emitter, type, content) do
    send(receiver, {:agent_event, %{type: type, content: content, seq: seq}})
    # Seq is per-struct, but since we use maps we can track externally if needed
    _ = emitter
    :ok
  end

  @impl true
  def complete(%__MODULE__{receiver: receiver}) do
    send(receiver, {:agent_done, :completed})
    :ok
  end

  @impl true
  def fail(%__MODULE__{receiver: receiver}, reason) do
    send(receiver, {:agent_done, {:failed, reason}})
    :ok
  end
end
