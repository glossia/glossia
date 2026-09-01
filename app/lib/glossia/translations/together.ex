defmodule Glossia.Translations.Together do
  @moduledoc """
  Calls Together's OpenAI-compatible chat-completions endpoint.

  Qwen's hybrid reasoning mode is useful for hard problems, but adds avoidable
  latency and cost to the straightforward, bounded text transformation that a
  translation segment is. Together supports disabling that mode explicitly.
  Bifrost forwards the same OpenAI-compatible request shape to Together.
  """

  alias ReqLLM.Error.API.Request

  @doc "Generates one non-reasoning Together completion."
  def complete(model, api_key, base_url, messages, opts \\ [])
      when is_binary(model) and is_binary(api_key) and is_binary(base_url) and is_list(messages) do
    body = %{
      model: model,
      messages: messages,
      stream: false,
      reasoning: %{enabled: false}
    }

    body =
      case Keyword.get(opts, :max_tokens) do
        max_tokens when is_integer(max_tokens) and max_tokens > 0 ->
          Map.put(body, :max_tokens, max_tokens)

        _ ->
          body
      end

    request_options =
      opts
      |> Keyword.take([:plug, :receive_timeout])
      |> Keyword.merge(
        json: body,
        headers: [{"authorization", "Bearer #{api_key}"}]
      )

    case Req.post(completions_url(base_url), request_options) do
      {:ok, %Req.Response{status: status, body: response}} when status in 200..299 ->
        response_text(response)

      {:ok, %Req.Response{status: status, body: response}} ->
        {:error,
         Request.exception(
           reason: "HTTP #{status}: Request failed",
           status: status,
           response_body: response
         )}

      {:error, error} ->
        {:error, error}
    end
  end

  defp completions_url(base_url) do
    base_url
    |> URI.parse()
    |> URI.append_path("/chat/completions")
    |> URI.to_string()
  end

  defp response_text(%{
         "choices" => [%{"message" => %{"content" => text}, "finish_reason" => reason} | _]
       })
       when is_binary(text) do
    if reason == "length" do
      {:error, {:output_limit_reached, byte_size(text)}}
    else
      {:ok, text}
    end
  end

  defp response_text(_response), do: {:error, :invalid_together_response}
end
