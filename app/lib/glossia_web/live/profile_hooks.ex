defmodule GlossiaWeb.ProfileHooks do
  @moduledoc """
  LiveView on_mount hooks for the user profile layout.

  Loads the current user from the session and redirects to login
  if not authenticated. Does not load an account (handle-scoped).
  """

  use GlossiaWeb, :verified_routes

  import Phoenix.Component, only: [assign: 3]

  alias Glossia.Accounts

  def on_mount(:load_user_and_require_auth, _params, session, socket) do
    case session["user_id"] do
      nil ->
        {:halt, Phoenix.LiveView.redirect(socket, to: ~p"/auth/login")}

      user_id ->
        user = Accounts.get_user(user_id)

        if user do
          {:cont, assign(socket, :current_user, user)}
        else
          {:halt, Phoenix.LiveView.redirect(socket, to: ~p"/auth/login")}
        end
    end
  end
end
