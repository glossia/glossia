defmodule Glossia.Minimax do
  @moduledoc false

  @base_url "https://api.minimax.io/v1/text/chatcompletion_v2"
  @default_model "MiniMax-M1"

  @error_codes %{
    1000 => :unknown_error,
    1001 => :request_timeout,
    1002 => :rate_limited,
    1004 => :auth_failed,
    1008 => :insufficient_balance,
    1013 => :internal_service_error,
    1027 => :output_content_error,
    1039 => :token_limit_exceeded,
    2013 => :parameter_error
  }

  @doc """
  Non-streaming chat completion. Returns `{:ok, response}` or `{:error, reason}`.

  The response map contains `:content`, `:finish_reason`, and `:usage`.

  ## Options

    * `:model` - model name (default: `"MiniMax-M1"`)
    * `:temperature` - sampling temperature
    * `:top_p` - nucleus sampling parameter
    * `:max_tokens` - maximum completion tokens
    * `:api_key` - override the configured API key
    * `:req_options` - extra options passed to `Req.post/2` (useful for testing)

  """
  def chat(messages, opts \\ []) do
    with {:ok, api_key} <- fetch_api_key(opts) do
      body = build_body(messages, opts, stream: false)
      req_options = Keyword.get(opts, :req_options, [])

      case Req.post(build_req(api_key, req_options), json: body) do
        {:ok, %Req.Response{status: 200, body: body}} ->
          parse_response(body)

        {:ok, %Req.Response{status: status}} ->
          {:error, {:http_error, status}}

        {:error, exception} ->
          {:error, {:request_failed, exception}}
      end
    end
  end

  @doc """
  Streaming chat completion. Returns `{:ok, stream}` where `stream` is an
  `Enumerable` that yields delta content strings.

  Returns `{:error, reason}` on failure.

  Accepts the same options as `chat/2`.
  """
  def stream(messages, opts \\ []) do
    with {:ok, api_key} <- fetch_api_key(opts) do
      body = build_body(messages, opts, stream: true)
      req_options = Keyword.get(opts, :req_options, [])
      caller = self()
      ref = make_ref()

      task =
        Task.async(fn ->
          into_fun = fn {:data, data}, {req, resp} ->
            for line <- String.split(data, "\n", trim: true) do
              case parse_sse_line(line) do
                {:ok, content} when content != "" ->
                  send(caller, {ref, {:chunk, content}})

                _ ->
                  :ok
              end
            end

            {:cont, {req, resp}}
          end

          result = Req.post(build_req(api_key, req_options), json: body, into: into_fun)
          send(caller, {ref, {:done, result}})
        end)

      stream =
        Stream.resource(
          fn -> {ref, task} end,
          fn {ref, task} ->
            receive do
              {^ref, {:chunk, content}} ->
                {[content], {ref, task}}

              {^ref, {:done, {:ok, %Req.Response{status: 200}}}} ->
                {:halt, {ref, task}}

              {^ref, {:done, {:ok, %Req.Response{status: status}}}} ->
                raise "Minimax streaming failed with HTTP status #{status}"

              {^ref, {:done, {:error, exception}}} ->
                raise "Minimax streaming request failed: #{inspect(exception)}"
            end
          end,
          fn {_ref, task} -> Task.await(task, :infinity) end
        )

      {:ok, stream}
    end
  end

  defp fetch_api_key(opts) do
    case Keyword.get(opts, :api_key) do
      key when is_binary(key) and key != "" ->
        {:ok, key}

      _ ->
        case config() |> Keyword.get(:api_key) do
          key when is_binary(key) and key != "" -> {:ok, key}
          _ -> {:error, :not_configured}
        end
    end
  end

  defp config do
    Application.get_env(:glossia, __MODULE__, [])
  end

  defp build_req(api_key, req_options) do
    [url: @base_url, headers: [{"authorization", "Bearer #{api_key}"}]]
    |> Keyword.merge(req_options)
    |> Glossia.HTTP.new()
  end

  defp build_body(messages, opts, extra) do
    %{
      model: Keyword.get(opts, :model, @default_model),
      messages: Enum.map(messages, &normalize_message/1),
      stream: Keyword.get(extra, :stream, false)
    }
    |> maybe_put(:temperature, Keyword.get(opts, :temperature))
    |> maybe_put(:top_p, Keyword.get(opts, :top_p))
    |> maybe_put(:max_completion_tokens, Keyword.get(opts, :max_tokens))
  end

  defp normalize_message(%{role: role, content: content}) do
    %{role: to_string(role), content: to_string(content)}
  end

  defp maybe_put(map, _key, nil), do: map
  defp maybe_put(map, key, value), do: Map.put(map, key, value)

  defp parse_response(%{"base_resp" => %{"status_code" => code}}) when code != 0 do
    {:error, Map.get(@error_codes, code, :unknown_error)}
  end

  defp parse_response(%{"choices" => [%{"message" => %{"content" => content}} | _]} = body) do
    {:ok,
     %{
       content: content,
       finish_reason: get_in(body, ["choices", Access.at(0), "finish_reason"]),
       usage: body["usage"]
     }}
  end

  defp parse_response(_body) do
    {:error, :unexpected_response}
  end

  defp parse_sse_line("data: [DONE]"), do: :done

  defp parse_sse_line("data: " <> json_str) do
    case JSON.decode(json_str) do
      {:ok, %{"choices" => [%{"delta" => %{"content" => content}} | _]}} ->
        {:ok, content}

      {:ok, %{"base_resp" => %{"status_code" => code}}} when code != 0 ->
        {:error, Map.get(@error_codes, code, :unknown_error)}

      {:ok, _} ->
        :skip

      {:error, _} ->
        :skip
    end
  end

  defp parse_sse_line(_), do: :skip
end
