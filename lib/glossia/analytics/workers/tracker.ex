defmodule Glossia.Analytics.Worker.Tracker do
  use Oban.Worker

  @impl Oban.Worker
  def perform(%Oban.Job{
        args: %{"event_id" => event_id, "user" => %{"email" => user_email}, "props" => props}
      }) do
    if Application.get_env(:glossia, :env) == :prod do
      Posthog.capture(event_id, %{distinct_id: user_email, email: user_email, props: props})
    end

    :ok
  end
end
