defmodule Glossia.Web.WebhookController do
  use Glossia.Web, :controller

  require Logger

  alias Glossia.Projects
  alias Glossia.Projects.Project
  alias Glossia.Foundation.ContentSources.Core, as: ContentSources

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
    content_source = ContentSources.new(:github, vcs_id)

    with {:should_localize, true} <-
           {:should_localize, ContentSources.should_localize?(content_source, commit_sha)},
         {:project, %Project{} = project} <-
           {:project,
            Projects.find_project_by_repository(%{vcs_id: vcs_id, vcs_platform: :github})} do
      Projects.process_git_event(project, %{
        event: event,
        ref: ref,
        default_branch: default_branch,
        commit_sha: commit_sha
      })
      json(conn, nil)
    else
      {:should_localize, _} -> json(conn, nil)
      {:project, nil} -> json(conn, nil)
    end
  end

  defp github_event(conn, _) do
    json(conn, nil)
  end
end
