defmodule Glossia.Motivator do
  @spec motivate(message :: String.t()) :: :ok
  def motivate(message) do
    {:ok, _} =
      %{message: message}
      |> Glossia.Motivator.Workers.DiscordMessageSender.new()
      |> Oban.insert()

    :ok
  end
end
