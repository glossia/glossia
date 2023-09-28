defmodule Glossia.Features.Cloud.Docs.Web.Controllers.DocsController do
  use Glossia.Features.Cloud.Docs.Web.Helpers, :controller
  alias Glossia.Features.Cloud.Docs.Core.Content

  def show(conn, _params) do
    conn |> assign(:navigation, Content.navigation()) |> render(:show)
  end
end
