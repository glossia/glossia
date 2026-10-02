defmodule Glossia.Decisions.Jev do
  @moduledoc """
  TypeSafe's native decision interface. Jev answers predefined questions rather
  than generating text. Provider bodies and credentials never enter errors.
  """

  alias Glossia.Models.ModelIdentifier

  def evaluate(model, api_key, base_url, state, questions, opts \\ []) do
    url =
      (base_url || "https://api.typesafe.ai/v1")
      |> URI.parse()
      |> URI.append_path("/systemone")
      |> URI.to_string()

    request =
      [
        json: %{model: ModelIdentifier.provider_model(model), state: state, questions: questions},
        auth: {:bearer, api_key},
        receive_timeout: 60_000,
        retry: fn request, result -> retry(request, result, Keyword.get(opts, :retry_delay)) end,
        max_retries: 3,
        retry_log_level: false
      ]
      |> Keyword.merge(Keyword.take(opts, [:plug, :receive_timeout]))

    case Req.post(url, request) do
      {:ok, %Req.Response{status: status, body: %{"answers" => answers} = body}}
      when status in 200..299 and is_map(answers) ->
        {:ok, body}

      {:ok, %Req.Response{status: status}} when status in 200..299 ->
        {:error, :invalid_decision_response}

      {:ok, %Req.Response{status: status}} ->
        {:error, {:decision_request_failed, status}}

      {:error, _error} ->
        {:error, :decision_provider_unavailable}
    end
  end

  defp retry(_request, %Req.Response{status: status} = response, delay_override)
       when status in [408, 429] or status in 500..599 do
    case delay_override || Req.Response.get_retry_after(response) do
      delay when is_integer(delay) -> {:delay, min(delay, 30_000)}
      _ -> true
    end
  end

  defp retry(_request, %Req.TransportError{reason: reason}, _delay_override)
       when reason in [:timeout, :econnrefused, :closed], do: true

  defp retry(_request, %Req.HTTPError{protocol: :http2, reason: reason}, _delay_override)
       when reason in [:unprocessed, :pool_not_available], do: true

  defp retry(_request, _response, _delay_override), do: false
end
