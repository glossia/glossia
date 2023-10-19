defmodule Glossia.Motivator do
  @spec motivate(message :: String.t()) :: :ok
  def motivate(message) do
    {:ok, _} =
      %{message: message}
      |> Glossia.Analytics.Worker.Tracker.new()
      |> Oban.insert()

    :ok
  end
end
