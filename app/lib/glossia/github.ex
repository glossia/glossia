defmodule Glossia.Github do
  @moduledoc false

  alias Glossia.Github.Installations

  require Logger

  def webhook_secret do
    Application.get_env(:glossia, __MODULE__, [])
    |> Keyword.get(:webhook_secret)
    |> case do
      secret when is_binary(secret) and secret != "" -> secret
      _ -> nil
    end
  end

  def handle_webhook_event("push", event) do
    Logger.info("GitHub push webhook received",
      github_repo_id: get_in(event, ["repository", "id"]),
      github_ref: event["ref"]
    )

    handle_push_event(event)
  end

  def handle_webhook_event(
        _event_type,
        %{"action" => action, "installation" => installation} = event
      )
      when is_map(installation) do
    type = Map.get(event, "type", "installation")

    Logger.info("GitHub webhook received",
      github_event_action: action,
      github_event_type: type
    )

    handle_installation_event(action, installation)
  end

  def handle_webhook_event(_event_type, %{"action" => action} = event) do
    type = Map.get(event, "type", event |> Map.keys() |> Enum.join(","))

    Logger.info("GitHub webhook received",
      github_event_action: action,
      github_event_type: type
    )

    Logger.debug("Unhandled GitHub webhook action: #{action}")
    :ok
  end

  def handle_webhook_event(event_type, event) do
    Logger.info("GitHub webhook received (unhandled)",
      github_event_type: event_type,
      github_event_keys: event |> Map.keys() |> Enum.join(",")
    )

    :ok
  end

  defp handle_push_event(event) do
    repo_id = get_in(event, ["repository", "id"])
    ref = event["ref"]
    head_commit = event["head_commit"]

    with project when not is_nil(project) <-
           Glossia.Projects.get_project_by_github_repo_id(repo_id),
         true <- push_to_default_branch?(ref, project),
         commit when is_map(commit) <- head_commit do
      Glossia.TranslationSessions.TranslateWorker.new(%{
        "project_id" => project.id,
        "commit_sha" => commit["id"],
        "commit_message" => first_line(commit["message"]),
        "triggered_by" => "webhook"
      })
      |> Oban.insert()

      Logger.info("Enqueued translation for push",
        project_id: project.id,
        commit_sha: commit["id"]
      )
    else
      nil ->
        Logger.debug("No project found for GitHub repo_id: #{repo_id}")

      false ->
        Logger.debug("Push to non-default branch, skipping translation")

      _ ->
        Logger.debug("Push event missing head_commit")
    end

    :ok
  end

  defp push_to_default_branch?(ref, project) do
    default_branch = project.github_repo_default_branch || "main"
    ref == "refs/heads/#{default_branch}"
  end

  defp first_line(nil), do: nil
  defp first_line(text), do: text |> String.split("\n") |> hd()

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
