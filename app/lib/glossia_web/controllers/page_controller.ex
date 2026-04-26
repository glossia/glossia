defmodule GlossiaWeb.PageController do
  use GlossiaWeb, :controller

  def home(conn, _params) do
    case conn.assigns[:current_user] do
      %{account: %{has_access: true, handle: handle}} ->
        redirect(conn, to: ~p"/#{handle}")

      %{} ->
        redirect(conn, to: ~p"/interest")

      nil ->
        redirect(conn, to: ~p"/auth/login")
    end
  end
end
