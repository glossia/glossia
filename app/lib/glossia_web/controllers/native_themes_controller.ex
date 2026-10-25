defmodule GlossiaWeb.NativeThemesController do
  use GlossiaWeb, :controller

  alias Glossia.NativeThemes

  def index(conn, _params) do
    conn
    |> put_resp_header("cache-control", "public, max-age=300")
    |> json(NativeThemes.catalog())
  end
end
