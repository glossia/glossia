defmodule Glossia.Translations.LLM do
  @moduledoc """
  Runs a translation prompt against the resolved credential.

  API-key credentials go through `tuist/condukt` (agent runtime with real turn
  streaming). OAuth credentials — the local Claude/Codex dev sessions — go
  through `ReqLLM` directly, because Condukt's option set can't carry OAuth
  (`auth_mode`/`access_token`); ReqLLM supports it natively.

  Both `run/3` and `stream/4` return `{:ok, text}` or `{:error, reason}`.
  """

  alias Glossia.Translations.Agent
  alias Glossia.Models.ModelIdentifier

  @together_base_url "https://api.together.ai/v1"
  @codex_cli_timeout_ms 1_800_000
  @pi_cli_timeout_ms 1_800_000

  @doc "One-shot generation."
  def run(%{auth: {:api_key, key, base_url}, model: model}, system, user) do
    opts = request_options(model, key, base_url, system)

    case Condukt.run(user, opts) do
      {:ok, text} when is_binary(text) -> {:ok, text}
      {:error, reason} -> {:error, reason}
      other -> {:error, "unexpected condukt response: #{inspect(other)}"}
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
    case ReqLLM.generate_text(ModelIdentifier.to_req_llm(model), messages(system, user),
           auth_mode: :oauth,
           access_token: token
         ) do
      {:ok, response} -> {:ok, ReqLLM.Response.text(response) || ""}
      {:error, reason} -> {:error, reason}
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
        cond do
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

  defp codex_error_message(events) do
    Enum.find_value(events, fn
      %{"type" => "error", "message" => message} when is_binary(message) -> message
      %{"type" => "turn.failed", "error" => %{"message" => message}} -> message
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

  @doc "Streamed generation, forwarding turn events to `on_event`."
  def stream(%{auth: {:api_key, _key, _base_url}} = cred, system, user, on_event) do
    stream_via_condukt(cred, system, user, on_event)
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

  def stream(%{auth: {:oauth, _token}} = cred, system, user, on_event) do
    # ReqLLM handles the OAuth call but not through Condukt's streaming session,
    # so we wrap the non-streamed result in a single synthetic turn.
    on_event.(:turn_start)

    case run(cred, system, user) do
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

  defp stream_via_condukt(
         %{auth: {:api_key, key, base_url}, model: model},
         system,
         user,
         on_event
       ) do
    opts = request_options(model, key, base_url, system)

    case Agent.start_link(opts) do
      {:ok, pid} ->
        try do
          run_stream(pid, user, on_event)
        rescue
          error -> {:error, Exception.message(error)}
        after
          if Process.alive?(pid), do: GenServer.stop(pid, :normal, 5_000)
        end

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp run_stream(pid, user, on_event) do
    outcome =
      pid
      |> Condukt.stream(user)
      |> Enum.reduce(%{text: "", error: nil}, fn event, acc ->
        on_event.(event)
        reduce_event(acc, event)
      end)

    case outcome do
      %{error: nil, text: text} -> {:ok, text}
      %{error: reason} -> {:error, reason}
    end
  end

  defp reduce_event(acc, {:text, chunk}) when is_binary(chunk),
    do: %{acc | text: acc.text <> chunk}

  defp reduce_event(acc, {:error, reason}), do: %{acc | error: acc.error || reason}
  defp reduce_event(acc, _event), do: acc

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

  defp request_options(model, key, base_url, system) do
    {request_model, request_base_url} = request_model(model, base_url)

    [
      model: request_model,
      api_key: key,
      system_prompt: system,
      thinking_level: thinking_level(model)
    ]
    |> maybe_base_url(request_base_url)
  end

  # Together rejects the generic `reasoning_effort: "none"` value that Condukt
  # derives from `:off`. Passing nil explicitly overrides Condukt's `:medium`
  # default while leaving reasoning configuration out of the provider request.
  defp thinking_level(model) do
    case ModelIdentifier.split(model) do
      {:ok, {"togetherai", _provider_model}} -> nil
      _ -> :off
    end
  end

  defp request_model(model, base_url) do
    case ModelIdentifier.split(model) do
      {:ok, {"togetherai", provider_model}} ->
        {%{provider: :openai, id: provider_model}, base_url || @together_base_url}

      {:ok, _parts} ->
        {ModelIdentifier.to_req_llm(model), base_url}

      :error ->
        {model, base_url}
    end
  end
end
