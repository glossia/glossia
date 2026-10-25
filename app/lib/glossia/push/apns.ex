defmodule Glossia.Push.APNs do
  @moduledoc "Direct APNs HTTP/2 with ES256 provider authentication. Errors never include tokens."
  alias Glossia.Push.{Config, Credentials}

  @hosts %{
    "production" => "https://api.push.apple.com",
    "sandbox" => "https://api.sandbox.push.apple.com"
  }

  def deliver(installation, payload, opts) do
    with {:ok, config} <- Config.apns(installation.environment),
         {:ok, token} <- Credentials.apns(config, Config.credentials_cache()),
         true <- Keyword.fetch!(opts, :authorized?).() do
      url =
        URI.merge(Map.fetch!(@hosts, installation.environment), %URI{
          path: "/3/device/#{installation.token}"
        })

      options =
        Keyword.merge(Config.req_options(),
          finch: Glossia.Push.Finch,
          json: payload,
          headers: [
            {"authorization", "bearer " <> token},
            {"apns-topic", config.topic},
            {"apns-push-type", "alert"},
            {"apns-priority", "10"},
            {"apns-expiration", Integer.to_string(DateTime.to_unix(opts[:expires_at]))},
            {"apns-collapse-id", opts[:notification_id]}
          ],
          retry: false,
          redirect: false,
          receive_timeout: 10_000,
          pool_timeout: 5000
        )

      url |> URI.to_string() |> Req.post(options) |> classify(config)
    else
      false -> {:error, :notification_unavailable}
      {:error, :not_configured} -> {:error, :provider_disabled}
      _ -> {:retry, nil}
    end
  end

  defp classify({:ok, %Req.Response{status: 200}}, _), do: :ok

  defp classify({:ok, %Req.Response{status: 410, body: body}}, _) do
    at =
      with %{"timestamp" => ms} when is_integer(ms) <- body,
           {:ok, at} <- DateTime.from_unix(ms, :millisecond) do
        at
      else
        _ -> nil
      end

    {:invalid_token, unregistered_at: at}
  end

  defp classify({:ok, %Req.Response{status: 400, body: %{"reason" => "BadDeviceToken"}}}, _),
    do: {:invalid_token, []}

  defp classify(
         {:ok, %Req.Response{status: 403, body: %{"reason" => "ExpiredProviderToken"}}},
         config
       ) do
    Credentials.invalidate(:apns, config, Config.credentials_cache())
    {:retry, nil}
  end

  defp classify({:ok, %Req.Response{status: status} = response}, _)
       when status in [429, 500, 503],
       do: {:retry, retry_after(response)}

  defp classify({:error, _}, _), do: {:retry, nil}
  defp classify(_, _), do: {:error, :provider_rejected}

  @doc false
  def retry_after(response) do
    case Req.Response.get_header(response, "retry-after") do
      [value | _] ->
        case Integer.parse(value) do
          {seconds, ""} when seconds >= 0 -> seconds
          _ -> http_date_delay(value)
        end

      _ ->
        nil
    end
  end

  defp http_date_delay(value) do
    case :httpd_util.convert_request_date(String.to_charlist(value)) do
      {{_, _, _}, {_, _, _}} = date ->
        max(
          :calendar.datetime_to_gregorian_seconds(date) -
            :calendar.datetime_to_gregorian_seconds(:calendar.universal_time()),
          0
        )

      _ ->
        nil
    end
  end
end
