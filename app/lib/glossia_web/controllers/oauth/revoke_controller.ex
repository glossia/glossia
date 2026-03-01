defmodule GlossiaWeb.OAuth.RevokeController do
  use GlossiaWeb, :controller

  @behaviour Boruta.Oauth.RevokeApplication

  plug GlossiaWeb.Plugs.RateLimit,
    key_prefix: "oauth_revoke",
    scale: :timer.minutes(1),
    limit: 30,
    by: [:ip, :client_id]

  def revoke(%Plug.Conn{} = conn, _params) do
    Boruta.Oauth.revoke(conn, __MODULE__)
  end

  @impl Boruta.Oauth.RevokeApplication
  def revoke_success(conn) do
    send_resp(conn, 200, "")
  end

  @impl Boruta.Oauth.RevokeApplication
  def revoke_error(conn, error) do
    conn
    |> put_status(error.status)
    |> json(%{error: error.error, error_description: error.error_description})
  end
end
