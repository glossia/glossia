defmodule GlossiaWeb.PageController do
  use GlossiaWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end
