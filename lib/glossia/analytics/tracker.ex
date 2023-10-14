defmodule Glossia.Analytics.Tracker do
  use Modulex

  defimplementation do
    alias Glossia.Analytics.Posthog

    @impl true
    def track_visit(user, env \\ Application.get_env(:glossia, :env)) do
      if env == :prod do
        Posthog.capture("visit", %{distinct_id: user.email, email: user.email})
      end
    end
  end

  defbehaviour do
    alias Glossia.Accounts.User

    @doc """
    When Glossia is compiled for the Cloud plan, it
    tracks the visit of a user.
    """
    @callback track_visit(user :: User.t()) :: nil
    @callback track_visit(user :: User.t(), env: atom()) :: nil
  end
end
