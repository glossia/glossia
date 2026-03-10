defmodule GlossiaAgent.LLM.Client do
  @moduledoc """
  LLM API client dispatcher.
  Routes to Anthropic or OpenAI adapter based on the agent config's provider.
  """

  alias GlossiaAgent.Config.LLMConfig.AgentConfig

  @type message :: %{role: String.t(), content: String.t()}
  @type usage :: %{
          prompt_tokens: non_neg_integer(),
          completion_tokens: non_neg_integer(),
          total_tokens: non_neg_integer()
        }
  @type result :: %{text: String.t(), usage: usage()}

  @doc "Send a chat completion request to the configured LLM provider."
  @spec chat(AgentConfig.t(), String.t(), [message()]) :: result()
  def chat(%AgentConfig{} = cfg, model, messages) do
    provider = cfg.provider |> String.trim() |> String.downcase()

    case provider do
      "anthropic" -> GlossiaAgent.LLM.Anthropic.chat(cfg, model, messages)
      _ -> GlossiaAgent.LLM.OpenAI.chat(cfg, model, messages)
    end
  end

  @doc "Resolve API key from config (inline value or env var)."
  @spec resolve_api_key(AgentConfig.t()) :: String.t()
  def resolve_api_key(%AgentConfig{} = cfg) do
    inline = expand_env(cfg.api_key) |> String.trim()

    if inline != "" do
      inline
    else
      if String.trim(cfg.api_key_env) != "" do
        System.get_env(cfg.api_key_env) || ""
      else
        ""
      end
    end
  end

  @doc "Expand environment variable references in a string."
  @spec expand_env(String.t()) :: String.t()
  def expand_env(input) when is_binary(input) do
    # Handle {{env.VAR}} syntax
    result =
      Regex.replace(~r/\{\{\s*env\.([A-Za-z_][A-Za-z0-9_]*)\s*\}\}/, input, fn _, name ->
        System.get_env(name) || ""
      end)

    # Handle env.VAR prefix
    result =
      if String.starts_with?(result, "env.") do
        System.get_env(String.slice(result, 4..-1//1)) || ""
      else
        result
      end

    # Handle env:VAR syntax
    Regex.replace(~r/env:([A-Za-z_][A-Za-z0-9_]*)/, result, fn _, name ->
      System.get_env(name) || ""
    end)
  end

  def expand_env(_), do: ""

  @doc "Resolve headers for the configured provider."
  @spec resolve_headers(AgentConfig.t()) :: %{String.t() => String.t()}
  def resolve_headers(%AgentConfig{} = cfg) do
    base_headers =
      Enum.into(cfg.headers, %{}, fn {k, v} -> {k, expand_env(v)} end)

    provider = cfg.provider |> String.trim() |> String.downcase()

    if provider == "anthropic" do
      headers =
        if has_header?(base_headers, "x-api-key") do
          base_headers
        else
          key = resolve_api_key(cfg)

          if String.trim(key) != "",
            do: Map.put(base_headers, "x-api-key", key),
            else: base_headers
        end

      if has_header?(headers, "anthropic-version") do
        headers
      else
        Map.put(headers, "anthropic-version", "2023-06-01")
      end
    else
      if has_header?(base_headers, "authorization") do
        base_headers
      else
        key = resolve_api_key(cfg)

        if String.trim(key) != "" do
          Map.put(base_headers, "Authorization", "Bearer " <> key)
        else
          base_headers
        end
      end
    end
  end

  defp has_header?(headers, name) do
    normalized = String.downcase(name)
    Enum.any?(headers, fn {k, _} -> String.downcase(k) == normalized end)
  end
end
