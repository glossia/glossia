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

  def blog(conn, _params) do
    conn
    |> put_root_layout(html: {GlossiaWeb.MarketingLayouts, :root})
    |> put_layout(html: {GlossiaWeb.MarketingLayouts, :base})
    |> render(:blog)
  end

  def beta(conn, _params) do
    conn
    |> put_root_layout(html: {GlossiaWeb.MarketingLayouts, :root})
    |> put_layout(html: {GlossiaWeb.MarketingLayouts, :base})
    |> render(:beta)
  end

  def beta_added(conn, _params) do
    conn
    |> put_root_layout(html: {GlossiaWeb.MarketingLayouts, :root})
    |> put_layout(html: {GlossiaWeb.MarketingLayouts, :base})
    |> render(:beta_added)
  end
end
