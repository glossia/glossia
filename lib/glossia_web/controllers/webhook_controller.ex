defmodule GlossiaWeb.WebhookController do
  use GlossiaWeb, :controller

  require Logger

  def github(conn, _params) do
    event = conn |> get_req_header("x-github-event") |> List.first()
    payload = conn.assigns.raw_body |> Jason.decode!()

    Glossia.VCS.process_webhook(event, payload, :github)
    |> case do
      {module, function, attrs} -> module |> apply(function, attrs)
      nil -> nil
    end

    json(conn, nil)
  end
end
