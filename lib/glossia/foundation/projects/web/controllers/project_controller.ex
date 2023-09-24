defmodule Glossia.Foundation.Projects.Web.Controllers.ProjectController do
  use Glossia.Foundation.Application.Web.Helpers.App, :controller

  def show(conn, _params) do
    render(conn, :show)
  end
end
