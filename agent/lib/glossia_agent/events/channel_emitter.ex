defmodule GlossiaAgent.Events.ChannelEmitter do
  @moduledoc """
  Event emitter for remote mode.

  Connects to the Phoenix server via WebSocket and pushes events
  through a Phoenix Channel. Also writes status and event files
  for the sandbox polling mechanism.
  """

  @behaviour GlossiaAgent.Events.Emitter

  use Slipstream

  require Logger

  @events_path "/tmp/agent-events.jsonl"
  @status_path "/tmp/agent-status.json"

  defstruct [:pid, :module]

  @type t :: %__MODULE__{
          pid: pid(),
          module: module()
        }

  # --- Public API (Emitter interface) ---

  @doc """
  Create a new channel emitter that connects to the Phoenix server.

  ## Options

    * `:server_url` - HTTP(S) URL of the Phoenix server (required)
    * `:token` - Signed session token for authentication (required)
    * `:topic` - Channel topic to join, e.g. "agent:setup:123" (required)

  Blocks until the channel join succeeds (up to 30 seconds).
  """
  @spec new(keyword()) :: t()
  def new(opts) do
    caller = self()
    {:ok, pid} = Slipstream.start_link(__MODULE__, Keyword.put(opts, :caller, caller))

    receive do
      {:channel_ready, ^pid} -> :ok
    after
      30_000 -> raise "Timeout waiting for channel connection"
    end

    %__MODULE__{pid: pid, module: __MODULE__}
  end

  @impl GlossiaAgent.Events.Emitter
  def emit(%__MODULE__{pid: pid}, type, content) do
    GenServer.call(pid, {:push_event, type, content}, 30_000)
  end

  @impl GlossiaAgent.Events.Emitter
  def complete(%__MODULE__{pid: pid}) do
    GenServer.call(pid, :complete, 30_000)
  end

  @impl GlossiaAgent.Events.Emitter
  def fail(%__MODULE__{pid: pid}, reason) do
    GenServer.call(pid, {:fail, reason}, 30_000)
  end

  # --- Slipstream GenServer ---

  @impl Slipstream
  def init(opts) do
    token = Keyword.fetch!(opts, :token)
    server_url = Keyword.fetch!(opts, :server_url)
    topic = Keyword.fetch!(opts, :topic)
    caller = Keyword.fetch!(opts, :caller)

    ws_url =
      server_url
      |> String.replace(~r/^http:/, "ws:")
      |> String.replace(~r/^https:/, "wss:")

    uri = "#{ws_url}/agent/socket/websocket?token=#{URI.encode_www_form(token)}"

    File.write!(@events_path, "")
    write_status("running")

    socket =
      new_socket()
      |> assign(topic: topic, caller: caller, seq: 0)
      |> connect!(uri: uri)

    {:ok, socket}
  end

  @impl Slipstream
  def handle_connect(socket) do
    Logger.info("Connected to Phoenix server, joining #{socket.assigns.topic}")
    {:ok, join(socket, socket.assigns.topic)}
  end

  @impl Slipstream
  def handle_join(_topic, _response, socket) do
    Logger.info("Joined channel #{socket.assigns.topic}")
    send(socket.assigns.caller, {:channel_ready, self()})
    {:ok, socket}
  end

  @impl Slipstream
  def handle_disconnect(_reason, socket) do
    Logger.warning("Disconnected from Phoenix server")
    {:stop, :normal, socket}
  end

  # GenServer callbacks for emitter operations

  @impl true
  def handle_call({:push_event, type, content}, _from, socket) do
    seq = socket.assigns.seq

    payload = %{
      sequence: seq,
      event_type: type,
      content: content,
      metadata: "{}"
    }

    write_event(seq, type, content)

    socket =
      socket
      |> push(socket.assigns.topic, "event", payload)
      |> assign(seq: seq + 1)

    {:reply, :ok, socket}
  end

  @impl true
  def handle_call(:complete, _from, socket) do
    write_status("completed")
    socket = leave(socket, socket.assigns.topic)
    {:reply, :ok, socket}
  end

  @impl true
  def handle_call({:fail, reason}, _from, socket) do
    seq = socket.assigns.seq

    payload = %{
      sequence: seq,
      event_type: "error",
      content: reason,
      metadata: "{}"
    }

    write_event(seq, "error", reason)
    socket = push(socket, socket.assigns.topic, "event", payload)

    write_status("failed")
    socket = leave(socket, socket.assigns.topic)
    {:reply, :ok, socket}
  end

  # --- File I/O helpers ---

  defp write_status(status) do
    data = Jason.encode!(%{status: status, updated_at: DateTime.to_iso8601(DateTime.utc_now())})
    File.write!(@status_path, data)
  end

  defp write_event(seq, type, content) do
    event = %{
      type: type,
      content: content,
      _seq: seq,
      _ts: DateTime.to_iso8601(DateTime.utc_now())
    }

    File.write!(@events_path, Jason.encode!(event) <> "\n", [:append])
  end
end
