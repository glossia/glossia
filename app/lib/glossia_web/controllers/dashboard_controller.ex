defmodule GlossiaWeb.DashboardController do
  use GlossiaWeb, :controller

  def index(conn, _params) do
    user = conn.assigns.current_user

    if user.account.has_access do
      redirect(conn, to: "/#{user.account.handle}")
    else
      redirect(conn, to: ~p"/billing")
    end
  end
end
