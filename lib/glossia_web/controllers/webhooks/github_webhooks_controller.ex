defmodule GlossiaWeb.Controllers.Webhooks.GitHubWebhooksController do
  use GlossiaWeb.Helpers.App, :controller

  require Logger

  # Public

  def github(conn, _params) do
    event = conn |> get_req_header("x-github-event") |> List.first()
    conn |> github_event(event)
  end

  defp github_event(conn, "push") do
    json(conn, nil)
    # payload = conn.assigns.raw_body |> Jason.decode!()
    # commit_sha = payload |> get_in(["after"])
    # id_in_content_platform = payload |> get_in(["repository", "full_name"])
    # content_platform_module = Glossia.ContentSources.get_platform_module(:github)

    # with {:should_localize, true} <-
    #        {:should_localize,
    #         content_platform_module.should_localize?(id_in_content_platform, commit_sha)},
    #      {:content_source, %ContentSource{}} <-
    #        {:content_source,
    #        ContentSources.find_project_by_repository(%{
    #           id_in_content_platform: id_in_content_platform,
    #           content_platform: :github
    #         })} do
    #   FLAME.call(Glossia.EventProcessor, fn ->
    #     IO.puts("Hello world")
    #   end)

    #   # Projects.trigger_build(project, %{
    #   #   type: "new_content",
    #   #   version: commit_sha
    #   # })

    #   json(conn, nil)
    # else
    #   {:should_localize, _} -> json(conn, nil)
    #   {:project, nil} -> json(conn, nil)
    # end
  end

  defp github_event(conn, _) do
    json(conn, nil)
  end
end
