defmodule GlossiaAgent.Config.LLMConfig do
  @moduledoc """
  LLM configuration and agent config resolution.
  Ported from agent/config.ts / cli/internal/glossia/config.go
  """

  defmodule AgentConfig do
    @moduledoc "Configuration for a single LLM agent (coordinator or translator)."
    defstruct role: "",
              provider: "",
              base_url: "",
              chat_completions_path: "",
              api_key: "",
              api_key_env: "",
              model: "",
              temperature: nil,
              max_tokens: nil,
              headers: %{},
              timeout_seconds: 0

    @type t :: %__MODULE__{
            role: String.t(),
            provider: String.t(),
            base_url: String.t(),
            chat_completions_path: String.t(),
            api_key: String.t(),
            api_key_env: String.t(),
            model: String.t(),
            temperature: number() | nil,
            max_tokens: integer() | nil,
            headers: %{String.t() => String.t()},
            timeout_seconds: non_neg_integer()
          }
  end

  defstruct provider: "",
            base_url: "",
            chat_completions_path: "",
            api_key: "",
            api_key_env: "",
            coordinator_model: "",
            translator_model: "",
            temperature: nil,
            max_tokens: nil,
            headers: %{},
            timeout_seconds: 0,
            agents: []

  @type t :: %__MODULE__{
          provider: String.t(),
          base_url: String.t(),
          chat_completions_path: String.t(),
          api_key: String.t(),
          api_key_env: String.t(),
          coordinator_model: String.t(),
          translator_model: String.t(),
          temperature: number() | nil,
          max_tokens: integer() | nil,
          headers: %{String.t() => String.t()},
          timeout_seconds: non_neg_integer(),
          agents: [map()]
        }

  @doc "Parse LLM config from a TOML map."
  @spec from_toml(map() | nil) :: t()
  def from_toml(nil), do: %__MODULE__{}

  def from_toml(obj) when is_map(obj) do
    agents =
      (as_list(obj["agent"]) ++ as_list(obj["agents"]))
      |> Enum.filter(&is_map/1)
      |> Enum.map(&parse_partial_agent/1)

    %__MODULE__{
      provider: as_string(obj["provider"]),
      base_url: as_string(obj["base_url"]),
      chat_completions_path: as_string(obj["chat_completions_path"]),
      api_key: as_string(obj["api_key"]),
      api_key_env: as_string(obj["api_key_env"]),
      coordinator_model: as_string(obj["coordinator_model"]),
      translator_model: as_string(obj["translator_model"]),
      temperature: as_number_or_nil(obj["temperature"]),
      max_tokens: as_int_or_nil(obj["max_tokens"]),
      headers: as_string_map(obj["headers"]),
      timeout_seconds: as_int(obj["timeout_seconds"]),
      agents: agents
    }
  end

  @doc "Merge two LLM configs, with `over` taking precedence."
  @spec merge(t(), t()) :: t()
  def merge(base, over) do
    agents = merge_agents_by_role(base.agents, over.agents)

    %__MODULE__{
      provider: pick(over.provider, base.provider),
      base_url: pick(over.base_url, base.base_url),
      chat_completions_path: pick(over.chat_completions_path, base.chat_completions_path),
      api_key: pick(over.api_key, base.api_key),
      api_key_env: pick(over.api_key_env, base.api_key_env),
      coordinator_model: pick(over.coordinator_model, base.coordinator_model),
      translator_model: pick(over.translator_model, base.translator_model),
      temperature: if(over.temperature != nil, do: over.temperature, else: base.temperature),
      max_tokens: if(over.max_tokens != nil, do: over.max_tokens, else: base.max_tokens),
      headers: Map.merge(base.headers, over.headers),
      timeout_seconds:
        if(over.timeout_seconds > 0, do: over.timeout_seconds, else: base.timeout_seconds),
      agents: agents
    }
  end

  @doc "Resolve coordinator and translator AgentConfigs from an LLM config."
  @spec resolve_agents(t()) :: %{coordinator: AgentConfig.t(), translator: AgentConfig.t()}
  def resolve_agents(%__MODULE__{} = llm) do
    role_map =
      llm.agents
      |> Enum.filter(&is_map/1)
      |> Enum.into(%{}, fn agent ->
        role = String.downcase(String.trim(agent["role"] || ""))
        {role, agent}
      end)

    base = %AgentConfig{
      provider: llm.provider,
      base_url: llm.base_url,
      chat_completions_path: llm.chat_completions_path,
      api_key: llm.api_key,
      api_key_env: llm.api_key_env,
      temperature: llm.temperature,
      max_tokens: llm.max_tokens,
      headers: llm.headers,
      timeout_seconds: llm.timeout_seconds
    }

    coord = merge_agent(base, role_map["coordinator"])

    coord =
      if String.trim(coord.model) == "", do: %{coord | model: llm.coordinator_model}, else: coord

    coord = apply_agent_defaults(coord)

    trans = merge_agent(base, role_map["translator"])

    trans =
      if String.trim(trans.model) == "", do: %{trans | model: llm.translator_model}, else: trans

    # Translator inherits from coordinator where empty
    trans = %{
      trans
      | provider: pick(trans.provider, coord.provider),
        base_url: pick(trans.base_url, coord.base_url),
        chat_completions_path: pick(trans.chat_completions_path, coord.chat_completions_path),
        api_key: pick(trans.api_key, coord.api_key),
        api_key_env: pick(trans.api_key_env, coord.api_key_env),
        temperature: if(trans.temperature == nil, do: coord.temperature, else: trans.temperature),
        max_tokens: if(trans.max_tokens == nil, do: coord.max_tokens, else: trans.max_tokens),
        timeout_seconds:
          if(trans.timeout_seconds == 0, do: coord.timeout_seconds, else: trans.timeout_seconds),
        headers: Map.merge(coord.headers, trans.headers)
    }

    trans = apply_agent_defaults(trans)

    %{coordinator: coord, translator: trans}
  end

  @doc """
  Build a server-controlled translator config from generic LLM settings.

  Expected map shape:

      %{
        provider: "anthropic",
        model: "claude-3-5-sonnet-latest",
        authentication: %{
          api_key: "...",
          api_key_env: "ANTHROPIC_API_KEY"
        }
      }
  """
  @spec build_server_translator(map()) :: AgentConfig.t()
  def build_server_translator(llm) when is_map(llm) do
    auth = map_get_map(llm, :authentication)

    cfg = %AgentConfig{
      role: "translator",
      provider: as_string(map_get(llm, :provider)),
      base_url: as_string(map_get(llm, :base_url)),
      chat_completions_path: as_string(map_get(llm, :chat_completions_path)),
      api_key: pick(as_string(map_get(auth, :api_key)), as_string(map_get(llm, :api_key))),
      api_key_env:
        pick(as_string(map_get(auth, :api_key_env)), as_string(map_get(llm, :api_key_env))),
      model: as_string(map_get(llm, :model)),
      temperature: as_number_or_nil(map_get(llm, :temperature)),
      max_tokens: as_int_or_nil(map_get(llm, :max_tokens)),
      headers: as_string_map(map_get(llm, :headers)),
      timeout_seconds:
        if(as_int(map_get(llm, :timeout_seconds)) > 0,
          do: as_int(map_get(llm, :timeout_seconds)),
          else: 300
        )
    }

    apply_agent_defaults(cfg)
  end

  # -- Private -----------------------------------------------------------------

  defp merge_agent(base, nil), do: base

  defp merge_agent(base, over) when is_map(over) do
    %AgentConfig{
      role: base.role,
      provider: pick(as_string(over["provider"]), base.provider),
      base_url: pick(as_string(over["base_url"]), base.base_url),
      chat_completions_path:
        pick(as_string(over["chat_completions_path"]), base.chat_completions_path),
      api_key: pick(as_string(over["api_key"]), base.api_key),
      api_key_env: pick(as_string(over["api_key_env"]), base.api_key_env),
      model: pick(as_string(over["model"]), base.model),
      temperature:
        if(as_number_or_nil(over["temperature"]) != nil,
          do: as_number_or_nil(over["temperature"]),
          else: base.temperature
        ),
      max_tokens:
        if(as_int_or_nil(over["max_tokens"]) != nil,
          do: as_int_or_nil(over["max_tokens"]),
          else: base.max_tokens
        ),
      headers: Map.merge(base.headers, as_string_map(over["headers"])),
      timeout_seconds:
        if(as_int(over["timeout_seconds"]) > 0,
          do: as_int(over["timeout_seconds"]),
          else: base.timeout_seconds
        )
    }
  end

  defp apply_agent_defaults(%AgentConfig{} = cfg) do
    provider =
      if String.trim(cfg.provider) == "" do
        infer_provider(cfg.model)
      else
        String.trim(cfg.provider)
      end

    cfg = %{cfg | provider: provider}

    case provider do
      "openai" ->
        cfg
        |> maybe_set(:chat_completions_path, "/chat/completions")
        |> maybe_set(:base_url, "https://api.openai.com/v1")
        |> maybe_set(:api_key_env, "OPENAI_API_KEY")

      "gemini" ->
        cfg
        |> maybe_set(:chat_completions_path, "/chat/completions")
        |> maybe_set(:base_url, "https://generativelanguage.googleapis.com/v1beta/openai")
        |> maybe_set(:api_key_env, "GEMINI_API_KEY")
        |> Map.put(:provider, "openai")

      "anthropic" ->
        cfg
        |> maybe_set(:chat_completions_path, "/v1/messages")
        |> maybe_set(:base_url, "https://api.anthropic.com")
        |> maybe_set(:api_key_env, "ANTHROPIC_API_KEY")

      _ ->
        cfg
    end
  end

  defp infer_provider(model) do
    normalized = model |> String.trim() |> String.downcase()

    cond do
      String.starts_with?(normalized, "gemini") -> "gemini"
      String.starts_with?(normalized, "claude") -> "anthropic"
      String.starts_with?(normalized, "gpt") -> "openai"
      String.starts_with?(normalized, "o1") -> "openai"
      String.starts_with?(normalized, "o3") -> "openai"
      String.starts_with?(normalized, "o4") -> "openai"
      true -> "openai"
    end
  end

  defp maybe_set(%AgentConfig{} = cfg, field, default) do
    if String.trim(Map.get(cfg, field) || "") == "" do
      Map.put(cfg, field, default)
    else
      cfg
    end
  end

  defp merge_agents_by_role(base_agents, over_agents) do
    if over_agents == [] do
      base_agents
    else
      Enum.reduce(over_agents, base_agents, fn agent, acc ->
        role = String.downcase(String.trim(agent["role"] || ""))

        if role == "" do
          acc ++ [agent]
        else
          idx =
            Enum.find_index(acc, fn a -> String.downcase(String.trim(a["role"] || "")) == role end)

          if idx, do: List.replace_at(acc, idx, agent), else: acc ++ [agent]
        end
      end)
    end
  end

  defp parse_partial_agent(obj) when is_map(obj) do
    %{
      "role" => as_string(obj["role"]),
      "provider" => as_string(obj["provider"]),
      "base_url" => as_string(obj["base_url"]),
      "chat_completions_path" => as_string(obj["chat_completions_path"]),
      "api_key" => as_string(obj["api_key"]),
      "api_key_env" => as_string(obj["api_key_env"]),
      "model" => as_string(obj["model"]),
      "temperature" => as_number_or_nil(obj["temperature"]),
      "max_tokens" => as_int_or_nil(obj["max_tokens"]),
      "headers" => as_string_map(obj["headers"]),
      "timeout_seconds" => as_int(obj["timeout_seconds"])
    }
  end

  defp pick(primary, fallback) do
    if String.trim(primary || "") != "", do: primary, else: fallback
  end

  defp map_get(map, key) when is_map(map) and is_atom(key) do
    Map.get(map, key) || Map.get(map, Atom.to_string(key))
  end

  defp map_get(_map, _key), do: nil

  defp map_get_map(map, key) do
    case map_get(map, key) do
      value when is_map(value) -> value
      _ -> %{}
    end
  end

  defp as_string(nil), do: ""
  defp as_string(v) when is_binary(v), do: v
  defp as_string(_), do: ""

  defp as_number_or_nil(nil), do: nil
  defp as_number_or_nil(v) when is_number(v), do: v
  defp as_number_or_nil(_), do: nil

  defp as_int_or_nil(nil), do: nil
  defp as_int_or_nil(v) when is_integer(v), do: v
  defp as_int_or_nil(v) when is_float(v), do: trunc(v)
  defp as_int_or_nil(_), do: nil

  defp as_int(nil), do: 0
  defp as_int(v) when is_integer(v), do: v
  defp as_int(v) when is_float(v), do: trunc(v)
  defp as_int(_), do: 0

  defp as_list(nil), do: []
  defp as_list(list) when is_list(list), do: list
  defp as_list(_), do: []

  defp as_string_map(nil), do: %{}

  defp as_string_map(map) when is_map(map) do
    Enum.into(map, %{}, fn
      {k, v} when is_binary(v) -> {to_string(k), v}
      {k, _} -> {to_string(k), ""}
    end)
  end

  defp as_string_map(_), do: %{}
end
