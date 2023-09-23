defmodule Glossia.Foundation.Projects.Web.Controllers.ProjectController do
  use Glossia.Foundation.Application.Web.Helpers.App, :controller

  def show(conn, _params) do
    render(conn, :new)
  end

  def new(conn, _params) do
    conn
    |> put_open_graph_metadata(%{
      title: "New project",
      description: "Create a new project"
    })
    |> render(:new)
  end
end
