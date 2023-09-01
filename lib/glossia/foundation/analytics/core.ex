defmodule Glossia.Foundation.Analytics.Core do
  use Boundary

  def track_visit(user) do
    if Application.get_env(:glossia, :env) == :prod do
      Posthog.capture("visit", %{distinct_id: user.email, email: user.email})
    end
  end
end
