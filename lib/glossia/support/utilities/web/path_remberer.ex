defmodule Glossia.Support.Utilities.Web.PathRememberer do
  use Modulex

  defimplementation do
    @session_key :user_return_to

    import Plug.Conn
    require Logger

    def remember_current_path(%{method: "GET"} = conn) do
      current_path = Phoenix.Controller.current_path(conn)
      Logger.debug("Remembering current path: #{current_path}")
      put_session(conn, @session_key, current_path)
    end

    def remember_current_path(conn), do: conn

    def remembered_path(conn) do
      path = get_session(conn, @session_key)
      Logger.debug("Remembered path: #{path}")
      path
    end
  end

  defbehaviour do
    @callback remember_current_path(Plug.Conn.t()) :: Plug.Conn.t()
    @callback remembered_path(Plug.Conn.t()) :: String.t() | nil
  end
end
