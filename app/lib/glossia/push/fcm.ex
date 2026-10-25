defmodule Glossia.Push.FCM do
  @moduledoc "Android-only FCM HTTP v1. Data-only messages let native clients fence old registrations."
  alias Glossia.Push.{APNs, Config, Credentials}

  def deliver(installation, data, opts) do
    with {:ok, config} <- Config.fcm(),
         {:ok, token} <- Credentials.fcm(config, Config.credentials_cache()),
         true <- Keyword.fetch!(opts, :authorized?).() do
      ttl = max(DateTime.diff(opts[:expires_at], DateTime.utc_now()), 0)

      url =
        URI.merge("https://fcm.googleapis.com", %URI{
          path: "/v1/projects/#{config.project_id}/messages:send"
        })

      options =
        Keyword.merge(Config.req_options(),
          finch: Glossia.Finch,
          auth: {:bearer, token},
          json: %{
            "message" => %{
              "token" => installation.token,
              "data" => data,
              "android" => %{"priority" => "HIGH", "ttl" => "#{ttl}s"}
            }
          },
          retry: false,
          redirect: false,
          receive_timeout: 10_000,
          pool_timeout: 5000
        )

      url |> URI.to_string() |> Req.post(options) |> classify(config)
    else
      false -> {:error, :notification_unavailable}
      {:error, :not_configured} -> {:error, :provider_disabled}
      {:error, :credentials_rejected} -> {:error, :credentials_rejected}
      _ -> {:retry, nil}
    end
  end

  defp classify({:ok, %Req.Response{status: 200}}, _), do: :ok

  defp classify({:ok, %Req.Response{status: 401}}, config) do
    Credentials.invalidate(:fcm, config, Config.credentials_cache())
    {:retry, nil}
  end

  defp classify({:ok, %Req.Response{status: status} = response}, _)
       when status in [429, 500, 503],
       do: {:retry, APNs.retry_after(response)}

  defp classify({:ok, %Req.Response{status: status, body: body}}, _)
       when status in [400, 403, 404] do
    details =
      case body do
        %{"error" => %{"details" => details}} when is_list(details) -> details
        _ -> []
      end

    code =
      Enum.find_value(details, fn
        %{"@type" => "type.googleapis.com/google.firebase.fcm.v1.FcmError", "errorCode" => code} ->
          code

        _ ->
          nil
      end)

    token_violation? =
      code == "INVALID_ARGUMENT" and
        Enum.any?(details, fn
          %{"@type" => "type.googleapis.com/google.rpc.BadRequest", "fieldViolations" => fields}
          when is_list(fields) ->
            Enum.any?(fields, &match?(%{"field" => "message.token"}, &1))

          _ ->
            false
        end)

    if code in ["UNREGISTERED", "SENDER_ID_MISMATCH"] or token_violation?,
      do: {:invalid_token, []},
      else: {:error, :provider_rejected}
  end

  defp classify({:error, _}, _), do: {:retry, nil}
  defp classify(_, _), do: {:error, :provider_rejected}
end
