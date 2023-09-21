defmodule Glossia.Foundation.Analytics.Core.Tracker do
  use Application.Module

  defimplementation do
    import Glossia.Foundation.Utilities.Core.Plan
    alias Glossia.Foundation.Analytics.Core.Posthog

    @impl true
    def track_visit(user, env \\ Application.get_env(:glossia, :env)) do
      only_for_plans([:cloud]) do
        if env == :prod do
          Posthog.capture("visit", %{distinct_id: user.email, email: user.email})
        end
      end
    end
  end

  defbehaviour do
    alias Glossia.Foundation.Accounts.Core.Models.User

    @doc """
    When Glossia is compiled for the Cloud plan, it
    tracks the visit of a user.
    """
    @callback track_visit(user :: User.t()) :: nil
    @callback track_visit(user :: User.t(), env: atom()) :: nil
  end
end
