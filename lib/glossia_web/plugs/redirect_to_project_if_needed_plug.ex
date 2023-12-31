defmodule GlossiaWeb.Plugs.RedirectToProjectIfNeededPlug do
  @moduledoc false

  alias GlossiaWeb.Auth

  @spec init(Keyword.t()) :: Keyword.t()
  def init(options), do: options

  @spec call(Plug.Conn.t(), term()) :: Plug.Conn.t()
  def call(
        %{request_path: "/"} = conn,
        _opts
      ) do
    case Auth.authenticated_user(conn) do
      nil ->
        conn

      _user ->
        conn
    end
  end

  def call(conn, _opts), do: conn
end
