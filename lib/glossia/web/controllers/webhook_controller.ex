defmodule Glossia.Web.WebhookController do
  use Glossia.Web, :controller

  require Logger

  alias Glossia.Projects
  alias Glossia.Projects.Project

  # Public

  def github(conn, _params) do
    event = conn |> get_req_header("x-github-event") |> List.first()
    conn |> github_event(event)
  end

  defp github_event(conn, "push" = event) do
    payload = conn.assigns.raw_body |> Jason.decode!()
    ref = payload |> get_in(["ref"])
    commit_sha = payload |> get_in(["after"])
    vcs_id = payload |> get_in(["repository", "full_name"])
    default_branch = payload |> get_in(["repository", "default_branch"])

    project =
      Projects.find_project_by_repository(%{vcs_id: vcs_id, vcs_platform: :github})

    case project do
      %Project{} = project ->
        project
        |> Projects.process_git_event(%{
          event: event,
          ref: ref,
          default_branch: default_branch,
          commit_sha: commit_sha
        })

      _ ->
        nil
    end

    json(conn, nil)
  end

  defp github_event(conn, _) do
    json(conn, nil)
  end
end
