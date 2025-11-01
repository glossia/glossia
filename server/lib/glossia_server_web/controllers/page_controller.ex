defmodule GlossiaServerWeb.PageController do
  use GlossiaServerWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end
