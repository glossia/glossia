defmodule GlossiaWeb.ProjectController do
  use GlossiaWeb, :controller

  def show(conn, _params) do
    render(conn, :new)
  end

  def new(conn, _params) do
    render(conn, :new)
  end
end
