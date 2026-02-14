defmodule Glossia.Github do
  @moduledoc false

  require Logger

  def webhook_secret do
    Application.get_env(:glossia, __MODULE__, [])
    |> Keyword.get(:webhook_secret)
    |> case do
      secret when is_binary(secret) and secret != "" -> secret
      _ -> nil
    end
  end

  def handle_webhook_event(%{"action" => action} = event) do
    type = Map.get(event, "type", event |> Map.keys() |> Enum.join(","))

    Logger.info("GitHub webhook received",
      github_event_action: action,
      github_event_type: type
    )

    case action do
      _ ->
        Logger.debug("Unhandled GitHub webhook action: #{action}")
        :ok
    end
  end

  def handle_webhook_event(event) do
    Logger.info("GitHub webhook received (no action)",
      github_event_keys: event |> Map.keys() |> Enum.join(",")
    )

    :ok
  end
end
