defmodule Glossia.Logger.LokiBackend do
  @moduledoc false

  @behaviour :gen_event

  @default_format "$time $metadata[$level] $message\n"
  @default_labels %{
    "source" => "elixir-runtime"
  }
  @default_max_buffer 20
  @default_flush_interval_ms 1_000
  @default_http_timeout_ms 5_000

  defstruct level: :info,
            format: Logger.Formatter.compile(@default_format),
            metadata: [:request_id, :trace_id, :span_id],
            url: "http://glossia-loki:3100",
            org_id: nil,
            labels: @default_labels,
            max_buffer: @default_max_buffer,
            flush_interval_ms: @default_flush_interval_ms,
            http_timeout_ms: @default_http_timeout_ms,
            buffer: [],
            buffer_size: 0,
            timer_ref: nil

  @impl true
  def init(__MODULE__) do
    _ = :inets.start()
    _ = :ssl.start()

    config = Application.get_env(:logger, __MODULE__, [])

    {:ok, configure(%__MODULE__{}, config)}
  end

  @impl true
  def handle_call({:configure, options}, state) do
    {:ok, :ok, configure(state, options)}
  end

  @impl true
  def handle_event({level, _group_leader, {Logger, message, timestamp, metadata}}, state) do
    if meets_level?(level, state.level) do
      state
      |> enqueue({timestamp, level, message, metadata})
      |> then(&{:ok, &1})
    else
      {:ok, state}
    end
  end

  def handle_event(:flush, state) do
    {:ok, flush_buffer(cancel_timer(state))}
  end

  def handle_event(_event, state) do
    {:ok, state}
  end

  @impl true
  def handle_info(:flush, state) do
    {:ok, flush_buffer(%{state | timer_ref: nil})}
  end

  def handle_info(_message, state) do
    {:ok, state}
  end

  @impl true
  def code_change(_old_vsn, state, _extra) do
    {:ok, state}
  end

  @impl true
  def terminate(_reason, state) do
    _ = flush_buffer(cancel_timer(state))
    :ok
  end

  defp configure(state, options) do
    options =
      Keyword.merge(
        [
          level: :info,
          format: @default_format,
          metadata: [:request_id, :trace_id, :span_id],
          url: "http://glossia-loki:3100",
          org_id: nil,
          labels: @default_labels,
          max_buffer: @default_max_buffer,
          flush_interval_ms: @default_flush_interval_ms,
          http_timeout_ms: @default_http_timeout_ms
        ],
        options
      )

    %{
      state
      | level: Keyword.get(options, :level, :info),
        format: compile_format(Keyword.get(options, :format, @default_format)),
        metadata: Keyword.get(options, :metadata, [:request_id, :trace_id, :span_id]),
        url: Keyword.get(options, :url, "http://glossia-loki:3100"),
        org_id: Keyword.get(options, :org_id),
        labels: normalize_labels(Keyword.get(options, :labels, @default_labels)),
        max_buffer: Keyword.get(options, :max_buffer, @default_max_buffer),
        flush_interval_ms: Keyword.get(options, :flush_interval_ms, @default_flush_interval_ms),
        http_timeout_ms: Keyword.get(options, :http_timeout_ms, @default_http_timeout_ms)
    }
  end

  defp enqueue(state, entry) do
    state = %{
      state
      | buffer: [entry | state.buffer],
        buffer_size: state.buffer_size + 1
    }

    if state.buffer_size >= state.max_buffer do
      state
      |> cancel_timer()
      |> flush_buffer()
    else
      schedule_flush(state)
    end
  end

  defp schedule_flush(%{timer_ref: nil} = state) do
    timer_ref = Process.send_after(self(), :flush, state.flush_interval_ms)
    %{state | timer_ref: timer_ref}
  end

  defp schedule_flush(state), do: state

  defp cancel_timer(%{timer_ref: nil} = state), do: state

  defp cancel_timer(state) do
    _ = Process.cancel_timer(state.timer_ref)
    %{state | timer_ref: nil}
  end

  defp flush_buffer(%{buffer_size: 0} = state), do: state

  defp flush_buffer(state) do
    entries =
      state.buffer
      |> Enum.reverse()
      |> Enum.map(&format_entry(state, &1))

    payload = %{
      "streams" => [
        %{
          "stream" => state.labels,
          "values" => entries
        }
      ]
    }

    push_async(payload, state.url, state.org_id, state.http_timeout_ms)

    %{state | buffer: [], buffer_size: 0}
  end

  defp push_async(payload, url, org_id, timeout_ms) do
    headers = push_headers(org_id)
    endpoint = push_url(url)

    Task.start(fn ->
      with {:ok, body} <- Jason.encode(payload) do
        request = {String.to_charlist(endpoint), headers, ~c"application/json", body}
        http_options = [timeout: timeout_ms, connect_timeout: timeout_ms]

        case :httpc.request(:post, request, http_options, []) do
          {:ok, {{_version, status, _reason_phrase}, _headers, _response_body}}
          when status >= 200 and status < 300 ->
            :ok

          _ ->
            :error
        end
      end
    end)
  end

  defp push_headers(nil), do: [{~c"content-type", ~c"application/json"}]
  defp push_headers(""), do: [{~c"content-type", ~c"application/json"}]

  defp push_headers(org_id) do
    [
      {~c"x-scope-orgid", String.to_charlist(org_id)},
      {~c"content-type", ~c"application/json"}
    ]
  end

  defp push_url(url) do
    if String.ends_with?(url, "/loki/api/v1/push") do
      url
    else
      String.trim_trailing(url, "/") <> "/loki/api/v1/push"
    end
  end

  defp compile_format({module, function} = formatter) do
    if function_exported?(module, function, 4),
      do: formatter,
      else: Logger.Formatter.compile(@default_format)
  end

  defp compile_format(format) when is_binary(format), do: Logger.Formatter.compile(format)
  defp compile_format(_format), do: Logger.Formatter.compile(@default_format)

  defp normalize_labels(labels) when is_map(labels) do
    for {key, value} <- labels, into: %{} do
      {to_string(key), to_string(value)}
    end
  end

  defp normalize_labels(labels) when is_list(labels) do
    for {key, value} <- labels, into: %{} do
      {to_string(key), to_string(value)}
    end
  end

  defp normalize_labels(_labels), do: @default_labels

  defp meets_level?(message_level, backend_level) do
    Logger.compare_levels(normalize_level(message_level), normalize_level(backend_level)) != :lt
  end

  defp normalize_level(:warn), do: :warning
  defp normalize_level(level), do: level

  defp format_entry(state, {timestamp, level, message, metadata}) do
    filtered_metadata = filter_metadata(metadata, state.metadata)
    line = Logger.Formatter.format(state.format, level, message, timestamp, filtered_metadata)

    [timestamp_to_ns(timestamp), line_to_binary(line)]
  end

  defp filter_metadata(metadata, :all), do: metadata

  defp filter_metadata(metadata, allowed_keys) when is_list(allowed_keys) do
    Enum.filter(metadata, fn {key, _value} -> key in allowed_keys end)
  end

  defp filter_metadata(_metadata, _allowed_keys), do: []

  defp timestamp_to_ns(_timestamp) do
    Integer.to_string(System.system_time(:nanosecond))
  end

  defp line_to_binary(line) do
    line
    |> IO.iodata_to_binary()
    |> String.trim_trailing()
  end
end
