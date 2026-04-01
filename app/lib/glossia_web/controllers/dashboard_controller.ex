defmodule GlossiaWeb.DashboardController do
  use GlossiaWeb, :controller

  def index(conn, _params) do
    user = conn.assigns.current_user
    redirect(conn, to: ~p"/#{user.account.handle}")
  end
end
