defmodule Glossia.Sandbox.HarnessEventPoller do
  @moduledoc false

  @interval_ms 750

  def start(fetch_fun, caller, path, opts \\ [])
      when is_function(fetch_fun, 1) and is_pid(caller) and is_binary(path) do
    mapper = Keyword.get(opts, :mapper, &decode_agent_event/1)
    Task.start(fn -> loop(fetch_fun, caller, path, 0, mapper) end)
  end

  def stop(pid) when is_pid(pid) do
    ref = Process.monitor(pid)
    send(pid, :stop)

    receive do
      {:DOWN, ^ref, :process, _pid, _reason} -> :ok
    after
      5_000 ->
        Process.exit(pid, :kill)
        :ok
    end
  end

  defp loop(fetch_fun, caller, path, offset, mapper) do
    offset = emit_new_events(fetch_fun, caller, path, offset, mapper)

    receive do
      :stop ->
        emit_new_events(fetch_fun, caller, path, offset, mapper)
        :ok
    after
      @interval_ms ->
        loop(fetch_fun, caller, path, offset, mapper)
    end
  end

  defp emit_new_events(fetch_fun, caller, path, offset, mapper) do
    case fetch_fun.(path) do
      {:ok, content} when is_binary(content) and byte_size(content) > offset ->
        new = binary_part(content, offset, byte_size(content) - offset)

        # Only process through the last complete line; keep any trailing partial
        # line buffered (offset does not advance past it) so a JSONL record split
        # across two polls is not lost or garbled.
        case last_newline_index(new) do
          nil ->
            offset

          index ->
            new
            |> binary_part(0, index + 1)
            |> String.split("\n", trim: true)
            |> Enum.each(&send_event(caller, &1, mapper))

            offset + index + 1
        end

      _ ->
        offset
    end
  end

  defp last_newline_index(binary) do
    case :binary.matches(binary, "\n") do
      [] -> nil
      matches -> matches |> List.last() |> elem(0)
    end
  end

  defp send_event(caller, line, mapper) do
    line
    |> mapper.()
    |> List.wrap()
    |> Enum.each(fn
      %{"event_type" => event_type} = event when is_binary(event_type) ->
        send(caller, {:agent_event, event})

      _event ->
        :ok
    end)
  end

  defp decode_agent_event(line) do
    case JSON.decode(line) do
      {:ok, %{"event_type" => event_type} = event} when is_binary(event_type) ->
        event

      _ ->
        nil
    end
  end
end
