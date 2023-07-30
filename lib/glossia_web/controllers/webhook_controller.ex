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
      |> generate_vcs_token_for_cloning_and_update_access_token()
      |> filter_only_default_branch_events()
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
        Logger.info("Could not find a project associated to the repository", attrs)
      project ->
        Logger.info("Found project", project)
        attrs |> Map.put(:project_id, project.id)
    end
  end

  defp generate_vcs_token_for_cloning_and_update_access_token(nil) do
    nil
  end

  defp generate_vcs_token_for_cloning_and_update_access_token(%{} = attrs) do
    case attrs |> Map.has_key?(:project_id) do
      true ->
        Logger.info("Generating token for cloning the project", attrs)
        attrs
        |> Map.put(:access_token, Glossia.VersionControl.generate_token_for_cloning(attrs))

      false ->
        attrs
    end
  end

  def filter_only_default_branch_events(nil) do
    :ok
  end

  def filter_only_default_branch_events(%{} = attrs) do
    default_branch = Map.fetch!(attrs, :default_branch)
    branch = case Map.fetch!(attrs, :ref) |> String.split("/") do
      ["refs", "heads" | tail ] -> tail |> String.join("/")
      name when is_binary(name) -> name
      _ -> nil
    end

    case branch == default_branch do
      true ->
        attrs
      false ->
        Logger.info("Ignoring event for branch #{branch} as it is not the default branch #{default_branch}")
        nil
    end
  end

  defp trigger_build_when_project_present(nil) do
    :ok
  end

  defp trigger_build_when_project_present(%{} = attrs) do
    case attrs |> Map.has_key?(:project_id) do
      true ->
        Logger.info("Triggering build to process the git event", attrs)
        attrs |> Glossia.Events.process_git_event()
      _ -> :ok
    end
  end
end
