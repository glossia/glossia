defmodule GlossiaWeb.Plugs.OpsAuth do
  @moduledoc false

  def init(opts), do: opts

  def call(conn, _opts) do
    config = Application.get_env(:glossia, __MODULE__, [])
    password = Keyword.get(config, :password)

    if is_binary(password) and password != "" do
      username = Keyword.get(config, :username, "ops")
      Plug.BasicAuth.basic_auth(conn, username: username, password: password)
    else
      conn
      |> Plug.Conn.send_resp(403, "Ops dashboard is not configured")
      |> Plug.Conn.halt()
    end
  end
end
