defmodule GlossiaWeb.WebhookController do
  use GlossiaWeb, :controller

  require Logger

  # Public

  def github(conn, _params) do
    event = conn |> get_req_header("x-github-event") |> List.first()
    payload = conn.assigns.raw_body |> Jason.decode!()

    :ok =
      %{event: event, payload: payload, vcs_platform: :github}
      |> Glossia.VersionControl.process_webhook_event()
      |> find_project_and_update_project_id()
      |> generate_vcs_token_for_cloning_and_update_git_access_token()
      |> trigger_build_when_project_present()

    json(conn, nil)
  end

  # Private

  defp find_project_and_update_project_id(nil) do
    nil
  end

  defp find_project_and_update_project_id(%{} = attrs) do
    case attrs |> Glossia.Projects.find_project_by_repository() do
      nil -> attrs
      project -> attrs |> Map.put(:project_id, project.id)
    end
  end

  defp generate_vcs_token_for_cloning_and_update_git_access_token(nil) do
    nil
  end

  defp generate_vcs_token_for_cloning_and_update_git_access_token(%{} = attrs) do
    case attrs |> Map.has_key?(:project_id) do
      true ->
        attrs
        |> Map.put(:git_access_token, Glossia.VersionControl.generate_token_for_cloning(attrs))

      false ->
        attrs
    end
  end

  defp trigger_build_when_project_present(nil) do
    :ok
  end

  defp trigger_build_when_project_present(%{} = attrs) do
    case attrs |> Map.has_key?(:project_id) do
      true -> attrs |> Glossia.Builds.trigger_git_event_build()
      _ -> :ok
    end
  end
end
