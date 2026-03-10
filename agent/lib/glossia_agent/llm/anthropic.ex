defmodule GlossiaAgent.LLM.Anthropic do
  @moduledoc """
  Anthropic-compatible API adapter (also used for MiniMax).
  """

  alias GlossiaAgent.Config.LLMConfig.AgentConfig
  alias GlossiaAgent.LLM.Client

  @spec chat(AgentConfig.t(), String.t(), [Client.message()]) :: Client.result()
  def chat(%AgentConfig{} = cfg, model, messages) do
    if String.trim(cfg.base_url) == "", do: raise("llm base_url is required")
    if String.trim(model) == "", do: raise("llm model is required")

    url = String.trim_trailing(cfg.base_url, "/") <> cfg.chat_completions_path

    {system_parts, anthropic_messages} = split_messages(messages)

    max_tokens =
      if cfg.max_tokens != nil && cfg.max_tokens > 0, do: cfg.max_tokens, else: 1024

    body =
      %{model: model, max_tokens: max_tokens, messages: anthropic_messages}
      |> maybe_put(:temperature, cfg.temperature)
      |> maybe_put(:system, if(system_parts != [], do: Enum.join(system_parts, "\n\n")))

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

    if response.status >= 400 do
      error_msg =
        case response.body do
          %{"error" => %{"message" => msg}} when is_binary(msg) -> msg
          _ -> "status #{response.status}"
        end

      raise "llm error: #{error_msg}"
    end

    text =
      case response.body do
        %{"content" => content} when is_list(content) ->
          content
          |> Enum.filter(&(&1["type"] == "text"))
          |> Enum.map_join("", & &1["text"])

        _ ->
          ""
      end

    if String.trim(text) == "", do: raise("llm response missing text")

    input_tokens = get_in(response.body, ["usage", "input_tokens"]) || 0
    output_tokens = get_in(response.body, ["usage", "output_tokens"]) || 0

    %{
      text: text,
      usage: %{
        prompt_tokens: input_tokens,
        completion_tokens: output_tokens,
        total_tokens: input_tokens + output_tokens
      }
    }
  end

  defp split_messages(messages) do
    Enum.reduce(messages, {[], []}, fn msg, {system, user_msgs} ->
      case msg.role do
        "system" ->
          if String.trim(msg.content) != "" do
            {system ++ [msg.content], user_msgs}
          else
            {system, user_msgs}
          end

        role when role in ["user", "assistant"] ->
          {system, user_msgs ++ [%{role: role, content: msg.content}]}

        _ ->
          {system, user_msgs}
      end
    end)
  end

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
