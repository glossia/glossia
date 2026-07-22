defmodule Glossia.Github do
  @moduledoc false

  alias Glossia.Github.Installations
  alias Glossia.Projects

  require Logger

  def webhook_secret do
    Application.get_env(:glossia, __MODULE__, [])
    |> Keyword.get(:webhook_secret)
    |> case do
      secret when is_binary(secret) and secret != "" -> secret
      _ -> nil
    end
  end

  def handle_webhook_event(%{
        "action" => action,
        "pull_request" => pull_request,
        "repository" => repository
      })
      when is_map(pull_request) and is_map(repository) do
    Logger.info("GitHub pull request webhook received",
      github_event_action: action,
      github_repository_id: repository["id"],
      github_pull_request_number: pull_request["number"]
    )

    handle_pull_request_event(action, repository, pull_request)
  end

  def handle_webhook_event(%{"action" => action, "installation" => installation} = event)
      when is_map(installation) do
    type = Map.get(event, "type", "installation")

    Logger.info("GitHub webhook received",
      github_event_action: action,
      github_event_type: type
    )

    handle_installation_event(action, installation)
  end

  def handle_webhook_event(%{"action" => action} = event) do
    type = Map.get(event, "type", event |> Map.keys() |> Enum.join(","))

    Logger.info("GitHub webhook received",
      github_event_action: action,
      github_event_type: type
    )

    Logger.debug("Unhandled GitHub webhook action: #{action}")
    :ok
  end

  def handle_webhook_event(event) do
    Logger.info("GitHub webhook received (no action)",
      github_event_keys: event |> Map.keys() |> Enum.join(",")
    )

    :ok
  end

  defp handle_pull_request_event(action, repository, pull_request)
       when action in ["opened", "reopened", "closed"] do
    repo_id = repository["id"]
    number = pull_request["number"]
    {state, merged_at} = pull_request_state(action, pull_request)

    case Projects.update_setup_pull_request_state(repo_id, number, state, merged_at) do
      {:ok, project} ->
        Projects.broadcast_setup_pull_request(project)

        Logger.info("Updated setup pull request state",
          project_id: project.id,
          setup_pull_request_state: state
        )

      {:error, :setup_pull_request_not_found} ->
        Logger.debug("Pull request is not associated with a Glossia project setup",
          github_repository_id: repo_id,
          github_pull_request_number: number
        )

      {:error, reason} ->
        Logger.warning("Could not update setup pull request state",
          github_repository_id: repo_id,
          github_pull_request_number: number,
          reason: inspect(reason)
        )
    end

    :ok
  end

  defp handle_pull_request_event(action, _repository, _pull_request) do
    Logger.debug("Unhandled GitHub pull request action: #{action}")
    :ok
  end

  defp pull_request_state("closed", %{"merged" => true} = pull_request) do
    {"merged", parse_datetime(pull_request["merged_at"])}
  end

  defp pull_request_state("closed", _pull_request), do: {"closed", nil}
  defp pull_request_state(_action, _pull_request), do: {"open", nil}

  defp parse_datetime(value) when is_binary(value) do
    case DateTime.from_iso8601(value) do
      {:ok, datetime, _offset} -> datetime
      {:error, _reason} -> nil
    end
  end

  defp parse_datetime(_value), do: nil

  defp handle_installation_event("created", installation) do
    Logger.info("GitHub App installed",
      github_installation_id: installation["id"],
      github_account_login: get_in(installation, ["account", "login"])
    )

    :ok
  end

  defp handle_installation_event("deleted", installation) do
    github_id = installation["id"]

    case Installations.delete_installation_by_github_id(github_id) do
      {:ok, _} ->
        Logger.info("GitHub installation deleted", github_installation_id: github_id)

      {:error, :not_found} ->
        Logger.debug("GitHub installation not found for deletion",
          github_installation_id: github_id
        )
    end

    :ok
  end

  defp handle_installation_event("suspend", installation) do
    github_id = installation["id"]

    case Installations.get_installation_by_github_id(github_id) do
      nil ->
        Logger.debug("GitHub installation not found for suspend",
          github_installation_id: github_id
        )

      inst ->
        Installations.suspend_installation(inst)
        Logger.info("GitHub installation suspended", github_installation_id: github_id)
    end

    :ok
  end

  defp handle_installation_event("unsuspend", installation) do
    github_id = installation["id"]

    case Installations.get_installation_by_github_id(github_id) do
      nil ->
        Logger.debug("GitHub installation not found for unsuspend",
          github_installation_id: github_id
        )

      inst ->
        Installations.unsuspend_installation(inst)
        Logger.info("GitHub installation unsuspended", github_installation_id: github_id)
    end

    :ok
  end

  defp handle_installation_event(action, _installation) do
    Logger.debug("Unhandled GitHub installation action: #{action}")
    :ok
  end
end
