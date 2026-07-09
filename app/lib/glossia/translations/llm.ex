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

  @doc "One-shot generation."
  def run(%{auth: {:api_key, key, base_url}, model: model}, system, user) do
    opts = maybe_base_url([model: model, system_prompt: system, api_key: key], base_url)

    case Condukt.run(user, opts) do
      {:ok, text} when is_binary(text) -> {:ok, text}
      {:error, reason} -> {:error, reason}
      other -> {:error, "unexpected condukt response: #{inspect(other)}"}
    end
  rescue
    error -> {:error, Exception.message(error)}
  end

  def run(%{auth: {:oauth, token}, model: model}, system, user) do
    case ReqLLM.generate_text(model, messages(system, user),
           auth_mode: :oauth,
           access_token: token
         ) do
      {:ok, response} -> {:ok, ReqLLM.Response.text(response) || ""}
      {:error, reason} -> {:error, reason}
    end
  rescue
    error -> {:error, Exception.message(error)}
  end

  @doc "Streamed generation, forwarding turn events to `on_event`."
  def stream(%{auth: {:api_key, _key, _base_url}} = cred, system, user, on_event) do
    stream_via_condukt(cred, system, user, on_event)
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

  defp stream_via_condukt(%{auth: {:api_key, key, base_url}, model: model}, system, user, on_event) do
    opts = maybe_base_url([model: model, api_key: key, system_prompt: system], base_url)

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

  defp reduce_event(acc, {:text, chunk}) when is_binary(chunk), do: %{acc | text: acc.text <> chunk}
  defp reduce_event(acc, {:error, reason}), do: %{acc | error: acc.error || reason}
  defp reduce_event(acc, _event), do: acc

  defp messages(system, user) do
    [%{role: "system", content: system}, %{role: "user", content: user}]
  end

  defp maybe_base_url(opts, url) when is_binary(url) and url != "", do: Keyword.put(opts, :base_url, url)
  defp maybe_base_url(opts, _url), do: opts
end
