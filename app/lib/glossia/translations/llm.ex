defmodule Glossia.Translations.LLM do
  @moduledoc """
  Runs a translation prompt against the resolved credential.

  API-key and OAuth credentials both go through `ReqLLM` and let us state the
  output-token budget a translation needs. Bifrost completes ordinary responses
  reliably but does not terminate a compatible event stream, so translations
  publish their complete text after each model response instead of waiting for a
  stream to finish. A translation is a single tool-less turn, so that preserves
  its behavior while avoiding a gateway-dependent stream lifecycle.

  Both `run/3` and `stream/4` return `{:ok, text}` or `{:error, reason}`.
  """

  alias Glossia.Models.ModelIdentifier

  @together_base_url "https://api.together.ai/v1"
  @codex_cli_timeout_ms 1_800_000
  @pi_cli_timeout_ms 1_800_000

  # A reasoning model spends output tokens thinking before it writes a single
  # character of the translation, so a budget sized for the translation alone
  # truncates the response mid-thought and returns no content at all. ReqLLM
  # falls back to 4096 tokens for a model its catalog does not know, which is
  # not enough: Qwen3.5 spends around 5300 tokens translating a 344-byte
  # metadata block. Models whose catalog entry states an output limit keep
  # ReqLLM's own default, which is the provider's real ceiling.
  @uncatalogued_max_output_tokens 32_768

  # The gateway completes a non-streaming reasoning response only after the
  # model has finished thinking. Qwen regularly takes longer than ReqLLM's
  # 30-second OpenAI-compatible default, so that default abandons a request the
  # gateway is still successfully completing and turns one translation into
  # several avoidable retries. Keep the timeout bounded, but wide enough for a
  # complete translated segment.
  @model_receive_timeout_ms :timer.minutes(5)

  @doc "One-shot generation."
  def run(%{auth: {:api_key, key, base_url}, model: model}, system, user) do
    with {:ok, spec, opts} <- request(model, api_key_options(key, model), base_url) do
      case ReqLLM.generate_text(spec, messages(system, user), opts) do
        {:ok, response} -> response_text(response)
        {:error, reason} -> {:error, reason}
      end
    end
  rescue
    error -> {:error, Exception.message(error)}
  end

  def run(%{source: :codex_session}, system, user) do
    run_via_codex_cli(system, user)
  end

  def run(%{source: :pi_session, model: model}, system, user) do
    run_via_pi_cli(model, system, user)
  end

  def run(%{auth: {:oauth, token}, model: model}, system, user) do
    with {:ok, spec, opts} <- request(model, oauth_options(token), nil) do
      case ReqLLM.generate_text(spec, messages(system, user), opts) do
        {:ok, response} -> response_text(response)
        {:error, reason} -> {:error, reason}
      end
    end
  rescue
    error -> {:error, Exception.message(error)}
  end

  defp run_via_codex_cli(system, user) do
    prompt = system <> "\n\n" <> user

    case MuonTrap.cmd(
           "sh",
           [
             "-c",
             ~s(exec "$@" </dev/null),
             "sh",
             "codex",
             "exec",
             "--dangerously-bypass-approvals-and-sandbox",
             "--json",
             prompt
           ],
           stderr_to_stdout: true,
           into: "",
           timeout: @codex_cli_timeout_ms
         ) do
      {output, code} ->
        events = codex_events(output)
        text = events |> codex_agent_messages() |> Enum.join("\n")

        # The CLI exits 0 even when the turn fails (usage limits, provider
        # outages), reporting the reason as an `error`/`turn.failed` event, and
        # its raw output is mostly unrelated tool chatter. Prefer the reported
        # message so the failure is classified and shown accurately.
        #
        # `turn.failed` is authoritative: the turn did not finish, so any agent
        # message collected before it is partial and must not be published. A
        # bare `error` event can be a recovered tool error mid-turn, so it only
        # decides when no agent message came back.
        cond do
          message = codex_turn_failure(events) ->
            {:error, {:codex_cli_failed, code, message}}

          code == 0 and text != "" ->
            {:ok, text}

          message = codex_error_message(events) ->
            {:error, {:codex_cli_failed, code, message}}

          code == 0 ->
            {:error, :empty_codex_response}

          true ->
            {:error, {:codex_cli_failed, code, String.slice(output, 0, 2_000)}}
        end
    end
  end

  defp codex_events(output) do
    output
    |> String.split("\n", trim: true)
    |> Enum.flat_map(fn line ->
      case Jason.decode(line) do
        {:ok, %{"type" => _type} = event} -> [event]
        _ -> []
      end
    end)
  end

  defp codex_agent_messages(events) do
    Enum.flat_map(events, fn
      %{"type" => "item.completed", "item" => %{"type" => "agent_message", "text" => text}} ->
        [text]

      _ ->
        []
    end)
  end

  defp codex_turn_failure(events) do
    Enum.find_value(events, fn
      %{"type" => "turn.failed", "error" => %{"message" => message}} when is_binary(message) ->
        message

      %{"type" => "turn.failed"} ->
        "the codex turn failed"

      _ ->
        nil
    end)
  end

  defp codex_error_message(events) do
    Enum.find_value(events, fn
      %{"type" => "error", "message" => message} when is_binary(message) -> message
      _ -> nil
    end)
  end

  defp run_via_pi_cli(model, system, user) do
    with {:ok, provider, model_id} <- pi_model_parts(model) do
      case MuonTrap.cmd(
             "sh",
             [
               "-c",
               ~s(exec "$@" </dev/null),
               "sh",
               pi_executable(),
               "-p",
               "--no-tools",
               "--no-session",
               "--no-context-files",
               "--no-skills",
               "--no-prompt-templates",
               "--no-extensions",
               "--provider",
               provider,
               "--model",
               model_id,
               "--system-prompt",
               system,
               user
             ],
             stderr_to_stdout: true,
             into: "",
             timeout: @pi_cli_timeout_ms
           ) do
        {output, 0} ->
          case String.trim(output) do
            "" -> {:error, :empty_pi_response}
            text -> {:ok, text}
          end

        {output, code} ->
          {:error, {:pi_cli_failed, code, String.slice(output, 0, 2_000)}}
      end
    end
  end

  @doc "Generation, forwarding lifecycle events to `on_event`."
  def stream(%{auth: {:api_key, key, base_url}, model: model}, system, user, on_event) do
    complete_via_req_llm(model, api_key_options(key, model), base_url, system, user, on_event)
  end

  def stream(%{source: :codex_session}, system, user, on_event) do
    on_event.(:turn_start)

    case run_via_codex_cli(system, user) do
      {:ok, text} = ok ->
        on_event.({:text, text})
        on_event.(:turn_end)
        on_event.(:done)
        ok

      {:error, reason} = error ->
        on_event.({:error, reason})
        error
    end
  end

  def stream(%{source: :pi_session, model: model}, system, user, on_event) do
    on_event.(:turn_start)

    case run_via_pi_cli(model, system, user) do
      {:ok, text} = ok ->
        on_event.({:text, text})
        on_event.(:turn_end)
        on_event.(:done)
        ok

      {:error, reason} = error ->
        on_event.({:error, reason})
        error
    end
  end

  def stream(%{auth: {:oauth, token}, model: model}, system, user, on_event) do
    complete_via_req_llm(model, oauth_options(token), nil, system, user, on_event)
  end

  defp complete_via_req_llm(model, auth_options, base_url, system, user, on_event) do
    on_event.(:turn_start)

    with {:ok, spec, opts} <- request(model, auth_options, base_url),
         {:ok, response} <- ReqLLM.generate_text(spec, messages(system, user), opts),
         {:ok, text} <- response_text(response) do
      on_event.({:text, text})
      on_event.(:turn_end)
      on_event.(:done)
      {:ok, text}
    else
      {:error, reason} ->
        on_event.({:error, reason})
        {:error, reason}
    end
  rescue
    error ->
      message = Exception.message(error)
      on_event.({:error, message})
      {:error, message}
  end

  defp messages(system, user) do
    [%{role: "system", content: system}, %{role: "user", content: user}]
  end

  defp pi_model_parts(model) do
    case String.split(ModelIdentifier.normalize(model), "/", parts: 2) do
      [provider, model_id] when provider != "" and model_id != "" ->
        {:ok, provider, model_id}

      _ ->
        {:error, :invalid_pi_model}
    end
  end

  defp pi_executable, do: System.get_env("GLOSSIA_PI_PATH") || "pi"

  defp maybe_base_url(opts, url) when is_binary(url) and url != "",
    do: Keyword.put(opts, :base_url, url)

  defp maybe_base_url(opts, _url), do: opts

  # The model is resolved once, up front, and the resolved struct is what the
  # request carries. Resolving it here rather than letting `ReqLLM` resolve the
  # string again per call keeps a model the catalog does not know from warning
  # on every segment, and it is what tells us whether an output budget has to be
  # supplied.
  defp request(model, auth_options, base_url) do
    {request_model, request_base_url} = request_model(model, base_url)

    case ReqLLM.model(request_model) do
      {:ok, spec} ->
        opts =
          auth_options
          |> Keyword.put(:receive_timeout, @model_receive_timeout_ms)
          |> maybe_max_tokens(spec)
          |> maybe_base_url(request_base_url)

        {:ok, spec, opts}

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp api_key_options(key, model), do: [api_key: key] ++ reasoning_options(model)

  # The local Claude and Codex sessions are asked for no reasoning
  # configuration, which is how they have always been called.
  defp oauth_options(token), do: [auth_mode: :oauth, access_token: token]

  # Together rejects the generic `reasoning_effort: "none"`, answering the whole
  # request with a 400, so its models are asked for no reasoning configuration
  # at all and are given an output budget wide enough to think within instead.
  defp reasoning_options(model) do
    case ModelIdentifier.split(model) do
      {:ok, {"togetherai", _provider_model}} -> []
      _ -> [reasoning_effort: :none]
    end
  end

  defp maybe_max_tokens(opts, %{limits: %{output: output}})
       when is_integer(output) and output > 0,
       do: opts

  defp maybe_max_tokens(opts, _spec),
    do: Keyword.put(opts, :max_tokens, @uncatalogued_max_output_tokens)

  # A truncated completion is never a usable translation, and a reasoning model
  # that runs out of budget mid-thought returns no content whatsoever. Naming
  # the limit here is what keeps that from surfacing as an unexplained empty
  # translation further down the pipeline.
  defp response_text(response) do
    case ReqLLM.Response.finish_reason(response) do
      :length ->
        {:error, {:output_limit_reached, byte_size(ReqLLM.Response.text(response) || "")}}

      _reason ->
        {:ok, ReqLLM.Response.text(response) || ""}
    end
  end

  defp request_model(model, base_url) do
    case ModelIdentifier.split(model) do
      {:ok, {"togetherai", provider_model}} ->
        # Together is OpenAI-compatible, and ReqLLM has no `togetherai`
        # provider, so the request is made as OpenAI against Together's URL.
        {"openai:#{provider_model}", base_url || @together_base_url}

      {:ok, _parts} ->
        {ModelIdentifier.to_req_llm(model), base_url}

      :error ->
        {model, base_url}
    end
  end
end
