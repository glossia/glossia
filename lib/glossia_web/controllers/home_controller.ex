defmodule GlossiaWeb.HomeController do
  use GlossiaWeb, :controller

  def index(conn, _params) do
    if conn.assigns[:current_user] do
      conn
      |> put_root_layout(html: {GlossiaWeb.AppLayouts, :root})
      |> render(:index_authenticated)
    else
      conn
      |> put_root_layout(html: {GlossiaWeb.MarketingLayouts, :root})
      |> put_layout(false)
      |> render(:index_marketing)
    end
  end
end
