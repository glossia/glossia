defmodule GlossiaWeb.WebhookController do
  use GlossiaWeb, :controller

  require Logger

  # Public

  def github(conn, _params) do
    event = conn |> get_req_header("x-github-event") |> List.first()
    payload = conn.assigns.raw_body |> Jason.decode!()

    %{event: event, payload: payload, vcs_platform: :github}
      |> Glossia.VersionControl.process_webhook_event()
      |> find_project_and_update_project_id()
      |> generate_project_token_for_authentication()
      |> generate_vcs_token_for_cloning_and_update_access_token()
      |> filter_only_default_branch_events()
      |> trigger_build_when_project_present()

    json(conn, nil)
  end

  # Private

  defp find_project_and_update_project_id(nil) do
    nil
  end

  defp find_project_and_update_project_id(%{vcs_id: _vcs_id, vcs_platform: _vcs_platform} = attrs) do
    case attrs |> Glossia.Projects.find_project_by_repository() do
      nil ->
        Logger.info("Could not find a project associated to the repository", attrs)

      project ->
        Logger.info("Found project with id #{project.id}")
        attrs |> Map.put(:project_id, project.id)
    end
  end

  def generate_project_token_for_authentication(nil) do
    nil
  end

  def generate_project_token_for_authentication(%{project_id: project_id} = attrs) do
    attrs
    |> Map.put(:access_token, Glossia.Projects.generate_token_for_project_with_id(project_id))
  end

  defp generate_vcs_token_for_cloning_and_update_access_token(nil) do
    nil
  end

  defp generate_vcs_token_for_cloning_and_update_access_token(%{project_id: _project_id} = attrs) do
    attrs
    |> Map.put(:git_access_token, Glossia.VersionControl.generate_token_for_cloning(attrs))
  end

  def filter_only_default_branch_events(nil) do
    nil
  end

  def filter_only_default_branch_events(%{} = attrs) do
    default_branch = Map.fetch!(attrs, :default_branch)
    ["refs", "heads" | tail] = Map.fetch!(attrs, :ref) |> String.split("/")
    branch = tail |> Enum.join("/")

    case branch == default_branch do
      true ->
        attrs

      false ->
        Logger.info(
          "Ignoring event for branch #{branch} as it is not the default branch #{default_branch}"
        )

        nil
    end
  end

  defp trigger_build_when_project_present(nil) do
    nil
  end

  defp trigger_build_when_project_present(%{} = attrs) do
    case attrs |> Map.has_key?(:project_id) do
      true ->
        Logger.info("Triggering build to process the git event", attrs)
        attrs |> Glossia.Events.process_git_event()
        :ok
      _ ->
        :ok
    end
  end
end
