defmodule GlossiaWeb.OAuth.IntrospectController do
  use GlossiaWeb, :controller

  @behaviour Boruta.Oauth.IntrospectApplication

  plug GlossiaWeb.Plugs.RateLimit,
    key_prefix: "oauth_introspect",
    scale: :timer.minutes(1),
    limit: 30,
    by: :ip

  def introspect(%Plug.Conn{} = conn, _params) do
    Boruta.Oauth.introspect(conn, __MODULE__)
  end

  @impl Boruta.Oauth.IntrospectApplication
  def introspect_success(conn, response) do
    body = %{
      active: response.active,
      client_id: response.client_id,
      username: response.username,
      scope: response.scope,
      sub: response.sub,
      iss: response.iss,
      exp: response.exp,
      iat: response.iat
    }

    conn
    |> put_status(:ok)
    |> json(body)
  end

  @impl Boruta.Oauth.IntrospectApplication
  def introspect_error(conn, error) do
    conn
    |> put_status(error.status)
    |> json(%{error: error.error, error_description: error.error_description})
  end
end
