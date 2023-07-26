defmodule GlossiaWeb.WebhookController do
  use GlossiaWeb, :controller

  require Logger

  def github(conn, _params) do
    event = conn |> get_req_header("x-github-event") |> List.first()
    payload = conn.assigns.raw_body |> Jason.decode!()

    case Glossia.VCS.get_webhook_processor(event, payload, :github) do
      {:push, %{commit_sha: commit_sha, repository_id: repository_id, vcs: vcs}} ->
        case Glossia.Projects.find_project_by_repository(repository_id, vcs) do
          %Glossia.Projects.Project{} = project ->
            Glossia.Builder.trigger_build(%{
              project_id: project.id,
              event: :git_push,
              commit_sha: commit_sha,
              repository_id: repository_id,
              vcs: :github
            })

          nil ->
            nil
        end

      _ ->
        nil
    end

    json(conn, nil)
  end
end
