defmodule Glossia.Foundation.Accounts.Web.LiveViews.AuthLiveView do
  import Phoenix.LiveView
  import Phoenix.Component
  alias Glossia.Foundation.Accounts.Core.Repository
  use Glossia.Foundation.Application.Web.Helpers.Shared, :verified_routes

  def on_mount(:authenticated_user, _params, %{"user_token" => user_token}, socket) do
    case Repository.get_user_by_session_token(user_token) do
      nil ->
        {:cont, redirect(socket, ~p"/auth/login")}

      user ->
        {:cont, assign(socket, :authenticated_user, user)}
    end
  end

  def on_mount(:authenticated_user, _params, _session, socket) do
    {:halt, redirect(socket, to: ~p"/auth/login")}
  end
end