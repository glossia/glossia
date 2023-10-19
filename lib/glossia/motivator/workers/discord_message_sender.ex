defmodule Glossia.Motivator.Workers.DiscordMessageSender do
  use Oban.Worker

  @webhook_url "https://discord.com/api/webhooks/1126573247551512598/VDiIWvSQL8U1mu5uBadm5qJBIaNnESed1F7mbN32GYzluAP1IKG7A-WRuk-jIY1KsMbZ"

  @impl Oban.Worker
  def perform(%Oban.Job{
        args: %{"message" => message}
      }) do
    if Application.get_env(:glossia, :env) == :prod do
      payload = %{"content" => message}
      body = Jason.encode!(payload)

      case Req.post(@webhook_url, body: body, headers: [{"Content-Type", "application/json"}]) do
        {:ok, response} ->
          {:ok, response.body}

        {:error, reason} ->
          {:error, reason}
      end
    else
      :ok
    end
  end
end
