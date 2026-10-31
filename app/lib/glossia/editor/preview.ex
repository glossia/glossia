defmodule Glossia.Editor.Preview do
  @moduledoc """
  Explicit, owner-bound visual repository previews. Frames are JPEG data, never
  app HTML or proxy URLs. Local execution is disabled unless `trusted_local:
  true` is set under this module's application configuration (development only).

  Updates are partial Content field maps against the snapshot displayed when
  the session started. A save can advance its lock version only if the saved
  bytes equal the session's accepted content and its repository base is unchanged.
  `update/4` returns `{:ok, revision}` so consumers can fence queued old frames.
  """
  use GenServer

  alias Glossia.Editor
  alias Glossia.Editor.{Content, PreviewRuntime}

  @max_bytes 1_000_000
  @idle_ms 120_000
  @startup_ms 420_000
  @absolute_ms 900_000

  def start(user, project, file_id, owner) when is_pid(owner) do
    with :ok <- isolation(),
         {:ok, file} <- Editor.get_file(user, project, file_id),
         :ok <- editable(file) do
      DynamicSupervisor.start_child(
        __MODULE__.Supervisor,
        {__MODULE__, {user, project, file, owner}}
      )
    end
  end

  def start(_, _, _, _), do: {:error, :invalid_owner}

  def update(pid, file_id, version, values),
    do: call(pid, {:update, file_id, version, values})

  @doc """
  Accepts ordered pointer input from the session owner for its ready revision.

  Input is an exact string-key map: `type`, `x`, `y` for `click` (primary
  click/tap), plus `delta_x`, `delta_y` for `scroll`. All numbers are integers;
  coordinates are viewport pixels in 0..1199 / 0..799 and wheel deltas are
  -2000..2000. Returns `:ok` when queued, not when rendered. At most 32 inputs
  may be outstanding; callers must not retry accepted inputs. A content update
  supersedes queued input for older revisions; stopping cancels pending input.

  Errors are `:not_owner`, `:invalid_input`, `:stale`, `:not_ready`,
  `:unauthorized`, `:busy`, or `:stopped`.
  """
  def interact(pid, revision, input), do: call(pid, {:interact, revision, input})

  def stop(pid) do
    case call(pid, :stop) do
      {:error, :stopped} -> :ok
      result -> result
    end
  end

  def start_link(args), do: GenServer.start_link(__MODULE__, args)

  def child_spec(args),
    do: %{id: __MODULE__, start: {__MODULE__, :start_link, [args]}, restart: :temporary}

  def isolation do
    adapter = Glossia.Sandbox.adapter()
    Code.ensure_loaded(adapter)

    cond do
      adapter == Glossia.Sandbox.LocalAdapter && config(:trusted_local, false) == true -> :ok
      function_exported?(adapter, :preview_isolated?, 0) && adapter.preview_isolated?() -> :ok
      true -> {:error, :preview_requires_isolation}
    end
  end

  @impl true
  def init({user, project, file, owner}) do
    monitor = Process.monitor(owner)
    Process.send_after(self(), :absolute_deadline, @absolute_ms)
    timer = :erlang.start_timer(@startup_ms, self(), :idle_deadline)

    state = %{
      user: user,
      project: project,
      file: file,
      owner: owner,
      owner_ref: monitor,
      worker: nil,
      worker_ref: nil,
      revision: 0,
      input_sequence: 0,
      inputs: MapSet.new(),
      idle: timer,
      ready: false,
      content: file.draft_content || file.content
    }

    {:ok, state, {:continue, :start}}
  end

  @impl true
  def handle_continue(:start, state) do
    emit(state, %{status: :starting, message: "Preparing an isolated app preview."})
    parent = self()

    {pid, ref} =
      spawn_monitor(fn -> PreviewRuntime.run(parent, state.user, state.project, state.file) end)

    {:noreply, %{state | worker: pid, worker_ref: ref}}
  end

  @impl true
  def handle_call({:update, id, version, values}, _from, state) do
    with true <- id == state.file.id,
         {:ok, current} <- Editor.get_file(state.user, state.project, id),
         true <- current.lock_version == version && same_base?(state.file, current),
         true <-
           version == state.file.lock_version ||
             (is_integer(version) && version > state.file.lock_version &&
                (current.draft_content || current.content) == state.content),
         :ok <- editable(current),
         :ok <- bounded_values(values),
         {:ok, content} <- Content.update(current.format, state.content, values),
         true <- byte_size(content) <= @max_bytes do
      revision = state.revision + 1
      send(state.worker, {:update, revision, content, current})
      Process.cancel_timer(state.idle)

      timer =
        :erlang.start_timer(
          if(state.ready, do: @idle_ms, else: @startup_ms),
          self(),
          :idle_deadline
        )

      {:reply, {:ok, revision},
       %{
         state
         | revision: revision,
           idle: timer,
           content: content,
           file: current,
           ready: false
       }}
    else
      false -> {:reply, {:error, :stale}, state}
      {:error, reason} -> {:reply, {:error, reason}, state}
    end
  end

  def handle_call({:interact, revision, input}, {caller, _}, state) do
    cond do
      caller != state.owner ->
        {:reply, {:error, :not_owner}, state}

      not valid_input?(input) ->
        {:reply, {:error, :invalid_input}, state}

      not is_integer(revision) || revision != state.revision ->
        {:reply, {:error, :stale}, state}

      not state.ready ->
        {:reply, {:error, :not_ready}, state}

      not frame_authorized?(state) ->
        {:reply, {:error, :unauthorized}, state}

      MapSet.size(state.inputs) >= 32 ->
        {:reply, {:error, :busy}, state}

      true ->
        sequence = state.input_sequence + 1
        send(state.worker, {:interact, revision, sequence, input})

        {:reply, :ok,
         %{state | input_sequence: sequence, inputs: MapSet.put(state.inputs, sequence)}}
    end
  end

  def handle_call(:stop, _from, state) do
    emit(state, %{status: :stopped, message: "Preview stopped."})
    {:stop, :normal, :ok, state}
  end

  @impl true
  def handle_info({:preview_input_ack, worker, sequence}, %{worker: worker} = state)
      when is_integer(sequence) and sequence <= state.input_sequence do
    {:noreply, %{state | inputs: MapSet.reject(state.inputs, &(&1 <= sequence))}}
  end

  def handle_info({:preview_event, worker, event}, %{worker: worker} = state) do
    cond do
      Map.has_key?(event, :frame) && event.revision != state.revision ->
        {:noreply, state}

      Map.has_key?(event, :frame) ->
        if frame_authorized?(state) do
          emit(state, event)
          Process.cancel_timer(state.idle)

          {:noreply,
           %{state | idle: :erlang.start_timer(@idle_ms, self(), :idle_deadline), ready: true}}
        else
          emit(state, %{
            status: :error,
            message: "The editor snapshot or access changed. Start a new preview."
          })

          {:stop, :normal, state}
        end

      true ->
        emit(state, event)
        if event.status == :error, do: {:stop, :normal, state}, else: {:noreply, state}
    end
  end

  def handle_info({:DOWN, ref, :process, _, _}, %{owner_ref: ref} = state),
    do: {:stop, :normal, state}

  def handle_info({:DOWN, ref, :process, _, _}, %{worker_ref: ref} = state) do
    emit(state, %{
      status: :error,
      message: "The app preview stopped. Start a new preview to retry."
    })

    {:stop, :normal, state}
  end

  def handle_info({:timeout, ref, :idle_deadline}, %{idle: ref} = state) do
    emit(state, %{status: :stopped, message: "Preview expired. Start a new preview to continue."})
    {:stop, :normal, state}
  end

  def handle_info(:absolute_deadline, state) do
    emit(state, %{status: :stopped, message: "Preview expired. Start a new preview to continue."})
    {:stop, :normal, state}
  end

  def handle_info(_, state), do: {:noreply, state}

  defp emit(state, event),
    do:
      send(state.owner, {:editor_preview, self(), Map.put_new(event, :revision, state.revision)})

  defp editable(file) do
    cond do
      file.branch -> {:error, :publication_pending}
      not file.active || file.conflict -> {:error, :repository_changed}
      true -> :ok
    end
  end

  defp frame_authorized?(state) do
    with {:ok, current} <- Editor.get_file(state.user, state.project, state.file.id),
         :ok <- editable(current) do
      same_base?(state.file, current) &&
        (current.lock_version == state.file.lock_version ||
           (current.draft_content || current.content) == state.content)
    else
      _ -> false
    end
  end

  def same_base?(a, b),
    do:
      Enum.all?(
        [:path, :source_path, :locale, :blob_sha, :content, :format, :mode],
        &(Map.get(a, &1) == Map.get(b, &1))
      )

  defp bounded_values(values) when is_map(values) and map_size(values) <= 10_000 do
    if Enum.all?(values, fn {k, v} -> is_binary(k) && is_binary(v) end) &&
         Enum.reduce(values, 0, fn {k, v}, n -> n + byte_size(k) + byte_size(v) end) <= @max_bytes,
       do: :ok,
       else: {:error, :file_too_large}
  end

  defp bounded_values(_), do: {:error, :invalid_values}

  defp valid_input?(%{"type" => type, "x" => x, "y" => y} = input)
       when is_integer(x) and x >= 0 and x < 1200 and is_integer(y) and y >= 0 and y < 800 do
    case type do
      "click" ->
        map_size(input) == 3

      "scroll" ->
        map_size(input) == 5 &&
          Enum.all?([input["delta_x"], input["delta_y"]], fn delta ->
            is_integer(delta) && delta >= -2000 && delta <= 2000
          end)

      _ ->
        false
    end
  end

  defp valid_input?(_), do: false

  def config(key, default),
    do: Application.get_env(:glossia, __MODULE__, []) |> Keyword.get(key, default)

  defp call(pid, message) do
    GenServer.call(pid, message, 30_000)
  catch
    :exit, _ -> {:error, :stopped}
  end
end
