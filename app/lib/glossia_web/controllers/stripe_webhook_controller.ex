defmodule GlossiaWeb.StripeWebhookController do
  use GlossiaWeb, :controller

  require Logger

  alias Glossia.Stripe
  alias Glossia.Stripe.Webhook

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
        send_resp(conn, 400, "invalid")

      _ ->
        send_resp(conn, 400, "invalid")
    end
  end
end
