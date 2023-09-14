defmodule Glossia.Foundation.Projects.Web.Plugs.RedirectToDefaultProjectWhenAuthenticatedPlug do
  alias Glossia.Foundation.Accounts.Web.Helpers.Auth

  @moduledoc """
  If there is an authenticated user
  """
  @spec init(Keyword.t()) :: Keyword.t()
  def init(options), do: options

  @spec call(Conn.t(), term()) :: Conn.t()
  def call(
        %{request_path: "/"} = conn,
        _opts
      ) do
        case Auth.authenticated_user(conn) do
          nil -> conn
          user ->
            dbg(conn)
        end
  end

  def call(conn, _opts), do: conn
end
