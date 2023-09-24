defmodule Glossia.Features.Cloud.Docs.Web.Controllers.DocsController do
  use Glossia.Features.Cloud.Docs.Web.Helpers, :controller

  def show(conn, _params) do
    conn |> render(:show)
  end
end
