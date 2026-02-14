defmodule Glossia.Gitlab do
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

  def handle_webhook_event(%{"object_kind" => kind} = _event) do
    Logger.info("GitLab webhook received", gitlab_event_kind: kind)

    case kind do
      _ ->
        Logger.debug("Unhandled GitLab webhook kind: #{kind}")
        :ok
    end
  end

  def handle_webhook_event(event) do
    Logger.info("GitLab webhook received (unknown shape)",
      gitlab_event_keys: event |> Map.keys() |> Enum.join(",")
    )

    :ok
  end
end
