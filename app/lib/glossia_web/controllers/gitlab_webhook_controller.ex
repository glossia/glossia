defmodule GlossiaWeb.GitlabWebhookController do
  use GlossiaWeb, :controller

  require Logger

  alias Glossia.Gitlab
  alias Glossia.Gitlab.Webhook

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
        send_resp(conn, 400, "invalid")

      _ ->
        send_resp(conn, 400, "invalid")
    end
  end
end
