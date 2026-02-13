defmodule GlossiaWeb.DashboardController do
  use GlossiaWeb, :controller

  def index(conn, _params) do
    render(conn, :index, current_user: conn.assigns.current_user)
  end
end
