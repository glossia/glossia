defmodule GlossiaWeb.Plugs.MarketingRouter do
  @moduledoc false

  def init(opts), do: opts

  def call(conn, _opts) do
    case Glossia.Extensions.marketing_router().resolve(conn, conn.path_info) do
      %Plug.Conn{} = conn -> conn
      :not_found -> Plug.Conn.send_resp(conn, 404, "Not found")
    end
  end
end
