defmodule GlossiaAgent.LLM.OpenAI do
  @moduledoc """
  OpenAI-compatible API adapter.
  """

  alias GlossiaAgent.Config.LLMConfig.AgentConfig
  alias GlossiaAgent.LLM.Client

  @spec chat(AgentConfig.t(), String.t(), [Client.message()]) :: Client.result()
  def chat(%AgentConfig{} = cfg, model, messages) do
    if String.trim(cfg.base_url) == "", do: raise("llm base_url is required")
    if String.trim(model) == "", do: raise("llm model is required")

    url = String.trim_trailing(cfg.base_url, "/") <> cfg.chat_completions_path

    body =
      %{model: model, messages: messages}
      |> maybe_put(:temperature, cfg.temperature)
      |> maybe_put(:max_tokens, cfg.max_tokens)

    headers =
      Client.resolve_headers(cfg)
      |> ensure_header("Content-Type", "application/json")
      |> ensure_header("User-Agent", "glossia")

    timeout = if cfg.timeout_seconds > 0, do: cfg.timeout_seconds * 1000, else: 300_000

    response =
      Req.post!(url,
        json: body,
        headers: headers,
        receive_timeout: timeout,
        retry: false
      )

    parsed = normalize_response(response.body)

    if response.status >= 400 do
      error_msg =
        case parsed do
          %{"error" => %{"message" => msg}} when is_binary(msg) -> msg
          _ -> "status #{response.status}"
        end

      raise "llm error: #{error_msg}"
    end

    text =
      case parsed do
        %{"choices" => [%{"message" => %{"content" => content}} | _]} -> content
        _ -> ""
      end

    if String.trim(text) == "", do: raise("llm response missing choices")

    usage = parsed["usage"] || %{}

    %{
      text: text,
      usage: %{
        prompt_tokens: usage["prompt_tokens"] || 0,
        completion_tokens: usage["completion_tokens"] || 0,
        total_tokens: usage["total_tokens"] || 0
      }
    }
  end

  defp normalize_response(body) when is_list(body) do
    case body do
      [single] ->
        case single do
          %{"error" => %{"message" => msg}} -> raise "llm error: #{msg}"
          _ -> single
        end

      _ ->
        raise "llm response: unexpected array with #{length(body)} elements"
    end
  end

  defp normalize_response(body), do: body

  defp maybe_put(map, _key, nil), do: map
  defp maybe_put(map, key, value), do: Map.put(map, key, value)

  defp ensure_header(headers, name, value) do
    normalized = String.downcase(name)

    if Enum.any?(headers, fn {k, _} -> String.downcase(k) == normalized end) do
      headers
    else
      Map.put(headers, name, value)
    end
  end
end
