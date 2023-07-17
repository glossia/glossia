defmodule GlossiaWeb.HomeController do
  use GlossiaWeb, :controller

  def index(conn, _params) do
    if conn.assigns[:current_user] do
      render(conn, :index_authenticated)
    else
      conn |> put_root_layout(html: {GlossiaWeb.Layouts, :marketing}) |> render(:index_marketing)
    end
  end
end
