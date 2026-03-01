defmodule GlossiaWeb.StripeWebhookController do
  use GlossiaWeb, :controller

  require Logger

  alias Glossia.Stripe
  alias Glossia.Stripe.Webhook

  plug GlossiaWeb.Plugs.RateLimit,
    key_prefix: "webhook_stripe",
    scale: :timer.minutes(1),
    limit: 240,
    by: :ip,
    format: :text

  # Stripe webhooks are verified against the raw request body.
  # We store it via GlossiaWeb.BodyReader configured in the endpoint.
  def create(conn, _params) do
    secret = Stripe.webhook_secret()
    payload = conn.assigns[:raw_body] || ""

    with :ok <- Webhook.verify(conn.req_headers, payload, secret),
         {:ok, event} <- Jason.decode(payload) do
      _ = Stripe.handle_webhook_event(event)
      send_resp(conn, 200, "ok")
    else
      {:error, reason} ->
        Logger.warning("Stripe webhook rejected: #{inspect(reason)}")
        respond_invalid(conn, "stripe")

      _ ->
        respond_invalid(conn, "stripe")
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
