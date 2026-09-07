defmodule GlossiaWeb.GitlabWebhookController do
  use GlossiaWeb, :controller

  require Logger

  alias Glossia.Gitlab
  alias Glossia.Gitlab.Webhook

  plug GlossiaWeb.Plugs.RateLimit,
    key_prefix: "webhook_gitlab",
    scale: :timer.minutes(1),
    limit: 240,
    by: :ip,
    format: :text

  def create(conn, _params) do
    secret = Gitlab.webhook_secret()
    payload = conn.assigns[:raw_body] || ""

    with :ok <- Webhook.verify(conn.req_headers, payload, secret),
         {:ok, event} <- Jason.decode(payload) do
      _ = Gitlab.handle_webhook_event(event)
      send_resp(conn, 200, "ok")
    else
      {:error, reason} ->
        Logger.warning("GitLab webhook rejected: #{inspect(reason)}")
        respond_invalid(conn, "gitlab")

      _ ->
        respond_invalid(conn, "gitlab")
    end
  end

  defp respond_invalid(conn, provider) do
    key = "webhook_invalid:#{provider}:ip:#{GlossiaWeb.ClientIP.value(conn)}"

    case Glossia.RateLimiter.hit(key, :timer.minutes(1), 20) do
      {:allow, _count} ->
        send_resp(conn, 400, "invalid")

      {:deny, _retry_after_ms} ->
        send_resp(conn, 429, "too many invalid webhook attempts")
    end
  end
end
