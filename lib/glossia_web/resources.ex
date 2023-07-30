defmodule GlossiaWeb.Resources do
  # use PolicyWonk.Resource
  # use PolicyWonk.Load

  def load_resource(_conn, :project, _) do
    # case Plug.Conn.get_req_header(conn, "authorization") do
    #   ["Bearer " <> token] ->
    #     # assign(conn, :bearer_token, token)

    #   _ ->
    #     conn
    #     |> Plug.Conn.put_resp_header("www-authenticate", "Bearer")
    #     |> Plug.Conn.send_resp(401, "Unauthorized")
    #     |> Plug.Conn.halt()
    # end
  end
end
