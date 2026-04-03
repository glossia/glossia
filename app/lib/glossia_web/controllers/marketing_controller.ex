defmodule GlossiaWeb.MarketingController do
  use GlossiaWeb, :controller

  def show(conn, %{"path" => path}) do
    case Glossia.Extensions.marketing_router().resolve(conn, path) do
      %Plug.Conn{} = conn -> conn
      :not_found -> send_resp(conn, 404, "Not found")
    end
  end
end
