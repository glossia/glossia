defmodule Glossia.Features.Docs.Web.Controllers.DocsController do
  use Glossia.Features.Docs.Web.Helpers, :controller
  alias Glossia.Features.Docs.Core.Content

  def show(conn, _params) do
    conn |> assign(:navigation, Content.navigation()) |> render(:show)
  end
end
