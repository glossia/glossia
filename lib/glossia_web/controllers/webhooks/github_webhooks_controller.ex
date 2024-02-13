defmodule GlossiaWeb.Controllers.Webhooks.GitHubWebhooksController do
  use GlossiaWeb.Helpers.App, :controller

  require Logger

  alias Glossia.Projects, as: Projects
  alias Glossia.Projects.Project

  # Public

  def github(conn, _params) do
    event = conn |> get_req_header("x-github-event") |> List.first()
    conn |> github_event(event)
  end

  defp github_event(conn, "push") do
    payload = conn.assigns.raw_body |> Jason.decode!()
    commit_sha = payload |> get_in(["after"])
    id_in_content_source_platform = payload |> get_in(["repository", "full_name"])
    content_source_platform_module = Glossia.ContentSources.get_platform_module(:github)

    with {:should_localize, true} <-
           {:should_localize,
           content_source_platform_module.should_localize?(id_in_content_source_platform, commit_sha)},
         {:project, %Project{}} <-
           {:project,
            Projects.find_project_by_repository(%{
              id_in_content_source_platform: id_in_content_source_platform,
              content_source_platform: :github
            })} do
      FLAME.call(Glossia.EventProcessor, fn ->
        IO.puts("Hello world")
      end)

      # Projects.trigger_build(project, %{
      #   type: "new_content",
      #   version: commit_sha
      # })

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
