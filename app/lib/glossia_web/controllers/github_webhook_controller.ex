defmodule GlossiaWeb.GithubWebhookController do
  use GlossiaWeb, :controller

  require Logger

  alias Glossia.Github
  alias Glossia.Github.Webhook

  plug GlossiaWeb.Plugs.RateLimit,
    key_prefix: "webhook_github",
    scale: :timer.minutes(1),
    limit: 240,
    by: :ip,
    format: :text

  def create(conn, _params) do
    secret = Github.webhook_secret()
    payload = conn.assigns[:raw_body] || ""

    with :ok <- Webhook.verify(conn.req_headers, payload, secret),
         {:ok, event} <- Jason.decode(payload) do
      _ = Github.handle_webhook_event(event)
      send_resp(conn, 200, "ok")
    else
      {:error, reason} ->
        Logger.warning("GitHub webhook rejected: #{inspect(reason)}")
        respond_invalid(conn, "github")

      _ ->
        respond_invalid(conn, "github")
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
