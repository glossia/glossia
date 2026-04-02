defmodule GlossiaWeb.AdminHooks do
  @moduledoc """
  LiveView on_mount hooks for the super admin area.

  Hooks:
    - `:load_user` - loads current_user from session
    - `:require_super_admin` - halts if user is not a super admin
  """

  use GlossiaWeb, :verified_routes

  import Phoenix.Component, only: [assign: 3]

  alias Glossia.Accounts
  alias Glossia.Accounts.Scope

  def on_mount(:load_user, _params, session, socket) do
    user =
      case session["user_id"] do
        nil -> nil
        user_id -> Accounts.get_user(user_id)
      end

    {:cont,
     socket
     |> assign(:current_scope, Scope.for_user(user))
     |> assign(:current_user, user)
     |> assign(:impersonating_from, session["impersonating_from"])}
  end

  def on_mount(:require_super_admin, _params, _session, socket) do
    user = socket.assigns[:current_user]

    if user && user.super_admin do
      {:cont, socket}
    else
      {:halt, Phoenix.LiveView.redirect(socket, to: ~p"/dashboard")}
    end
  end
end
