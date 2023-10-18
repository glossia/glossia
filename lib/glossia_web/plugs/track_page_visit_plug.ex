defmodule TrackPageVisitPlug do
  @moduledoc false

  @spec init(Keyword.t()) :: Keyword.t()
  def init(options), do: options

  @spec call(Plug.Conn.t(), term()) :: Plug.Conn.t()
  def call(%{request_path: request_path} = conn, _opts) do
    case GlossiaWeb.Auth.authenticated_user(conn) do
      nil ->
        conn

      %Glossia.Accounts.User{} = user ->
        Glossia.Analytics.track("page_visit", user, %{request_path: request_path})
        conn
    end
  end
end
