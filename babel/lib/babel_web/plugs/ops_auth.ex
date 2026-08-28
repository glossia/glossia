defmodule BabelWeb.Plugs.OpsAuth do
  @moduledoc false

  import Plug.BasicAuth

  def init(opts), do: opts

  def call(conn, _opts) do
    config = Application.get_env(:babel, __MODULE__, [])

    if Keyword.get(config, :enabled, false) do
      basic_auth(conn,
        username: Keyword.fetch!(config, :username),
        password: Keyword.fetch!(config, :password)
      )
    else
      conn
    end
  end
end
