defmodule GlossiaWeb.LiveViews.AuthLiveView do
  import Phoenix.LiveView
  import Phoenix.Component
  alias Glossia.Accounts.Repository
  use GlossiaWeb.Helpers.Shared, :verified_routes

  def on_mount(:authenticated_user, _params, %{"user_token" => user_token}, socket) do
    case Glossia.Accounts.get_user_by_session_token(user_token) do
      nil ->
        {:halt, redirect(socket, to: ~p"/auth/login")}

      user ->
        {:cont, assign(socket, :authenticated_user, user)}
    end
  end

  def on_mount(:authenticated_user, _params, _session, socket) do
    {:halt, redirect(socket, to: ~p"/auth/login")}
  end
end
