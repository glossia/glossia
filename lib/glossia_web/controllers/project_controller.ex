defmodule GlossiaWeb.Controllers.ProjectController do
  use GlossiaWeb.Helpers.App, :controller

  def show(conn, _params) do
    render(conn, :show)
  end
end
