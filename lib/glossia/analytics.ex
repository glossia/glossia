defmodule Glossia.Analytics do
  @moduledoc false

  @spec track(event_id :: String.t(), user :: %{id: any(), email: binary()}) :: :ok
  def track(event_id, user, props \\ %{}) do
    if Application.get_env(:glossia, :env) == :prod do
      {:ok, _} =
        %{event_id: event_id, user: user, props: props}
        |> Glossia.Analytics.Worker.Tracker.new()
        |> Oban.insert()

      :ok
    else
      :ok
    end
  end
end
