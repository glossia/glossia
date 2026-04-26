defmodule GlossiaWeb.RetiredPublicController do
  use GlossiaWeb, :controller

  def show(conn, _params) do
    send_resp(conn, 404, "Not found")
  end

  def search_index(conn, _params) do
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(404, ~s({"error":"not_found"}))
  end
end
