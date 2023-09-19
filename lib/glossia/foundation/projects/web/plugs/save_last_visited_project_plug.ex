defmodule Glossia.Foundation.Projects.Web.Plugs.SaveLastVisitedProjectPlug do
  @moduledoc """
  If there is an authenticated user
  """
  @spec init(Keyword.t()) :: Keyword.t()
  def init(options), do: options

  @spec call(Plug.Conn.t(), term()) :: Plug.Conn.t()
  def call(%{assigns: %{url_project: url_project}} = conn, _opts) do
    authenticated_user = Glossia.Foundation.Accounts.Web.authenticated_user(conn)

    case {authenticated_user, url_project} do
      {nil, _} ->
        conn

      {_, nil} ->
        conn

      {_user, _project} ->
        conn
    end
  end

  def call(conn, _opts), do: conn
end
