defmodule GlossiaWeb.Plugs.LoadAuthenticatedUserPlug do
  @moduledoc """
  :authenticated_user
  """

  import Plug.Conn
  alias Plug.Conn

  @authenticated_user_key :authenticated_user

  @spec init(Keyword.t()) :: Keyword.t()
  def init(options), do: options

  @spec call(Conn.t(), term()) :: Conn.t()
  def call(%Conn{method: method} = conn, _opts) when method == "POST" or method == "PUT" do
    with {user_token, _} when user_token != nil <- get_conn_token(conn),
         {:user, user} when user != nil <-
           {:user, Glossia.Accounts.get_user_by_session_token(user_token)} do
      conn |> assign(@authenticated_user_key, user)
    else
      _ ->
        conn
    end
  end

  def call(conn, _opts), do: conn

  @spec authenticated?(Conn.t()) :: boolean()
  def authenticated?(conn) do
    conn.assigns[@authenticated_user_key] != nil
  end

  @spec authenticated_user(conn :: Plug.Conn.t()) :: Glossia.Accounts.Models.User.t() | nil
  def authenticated_user(conn) do
    conn.assigns[@authenticated_user_key]
  end

  @spec get_conn_token(conn :: Plug.Conn.t()) :: {String.t() | nil, Plug.Conn.t()}
  defp get_conn_token(conn) do
    if token = get_session(conn, :user_token) do
      {token, conn}
    else
      conn = fetch_cookies(conn, signed: [GlossiaWeb.Helpers.Auth.remember_me_cookie()])

      if token = conn.cookies[GlossiaWeb.Helpers.Auth.remember_me_cookie()] do
        {token, GlossiaWeb.Helpers.Auth.put_token_in_session(conn, token)}
      else
        {nil, conn}
      end
    end
  end
end
