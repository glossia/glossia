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
