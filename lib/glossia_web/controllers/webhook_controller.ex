defmodule GlossiaWeb.WebhookController do
  use GlossiaWeb, :controller

  require Logger

  def github(conn, _params) do
    event = conn |> get_req_header("x-github-event") |> List.first()
    payload = conn.assigns.raw_body |> Jason.decode!()

    case Glossia.VCS.get_webhook_processor(event, payload, :github) do
      {:translate, %{commit_sha: commit_sha, repository_id: repository_id, vcs: :github}} ->
        Glossia.Translations.translate(
          commit_sha: commit_sha,
          repository_id: repository_id,
          vcs: :github
        )

      _ ->
        nil
    end

    json(conn, nil)
  end
end
