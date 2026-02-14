defmodule GlossiaWeb.GithubWebhookController do
  use GlossiaWeb, :controller

  require Logger

  alias Glossia.Github
  alias Glossia.Github.Webhook

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
        send_resp(conn, 400, "invalid")

      _ ->
        send_resp(conn, 400, "invalid")
    end
  end
end
