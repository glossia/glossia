defmodule GlossiaWeb.ProjectController do
  use GlossiaWeb, :controller

  def new(conn, _params) do
    render(conn, :new)
  end
end
