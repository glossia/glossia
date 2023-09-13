defmodule Glossia.Foundation.Projects.Web.Controllers.ProjectController do
  use Glossia.Foundation.Application.Web, :controller

  def show(conn, _params) do
    render(conn, :new)
  end

  def new(conn, _params) do
    render(conn, :new)
  end
end
