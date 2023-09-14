defmodule Glossia.Foundation.ContentSources.Web.Controllers.GitHub.WebhookController do
  use Glossia.Foundation.Application.Web, :controller

  require Logger

  alias Glossia.Foundation.Projects.Core, as: Projects
  alias Glossia.Foundation.Projects.Core.Project
  alias Glossia.Foundation.ContentSources.Core, as: ContentSources

  # Public

  def github(conn, _params) do
    event = conn |> get_req_header("x-github-event") |> List.first()
    conn |> github_event(event)
  end

  defp github_event(conn, "push") do
    payload = conn.assigns.raw_body |> Jason.decode!()
    commit_sha = payload |> get_in(["after"])
    content_source_id = payload |> get_in(["repository", "full_name"])
    content_source = ContentSources.new(:github, content_source_id)

    with {:should_localize, true} <-
           {:should_localize, ContentSources.should_localize?(content_source, commit_sha)},
         {:project, %Project{} = project} <-
           {:project,
            Projects.find_project_by_repository(%{
              content_source_id: content_source_id,
              content_source_platform: :github
            })} do
      Projects.trigger_build(project, %{
        type: "new_content",
        version: commit_sha
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
