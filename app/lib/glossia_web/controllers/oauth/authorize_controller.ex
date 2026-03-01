defmodule GlossiaWeb.OAuth.AuthorizeController do
  use GlossiaWeb, :controller

  @behaviour Boruta.Oauth.AuthorizeApplication

  plug GlossiaWeb.Plugs.RateLimit,
    key_prefix: "oauth_authorize",
    scale: :timer.minutes(1),
    limit: 30,
    by: :user,
    format: :text

  # GET /oauth/authorize - preauthorize: validate request, show consent screen
  def authorize(%Plug.Conn{method: "GET"} = conn, _params) do
    resource_owner = current_resource_owner(conn)
    Boruta.Oauth.preauthorize(conn, resource_owner, __MODULE__)
  end

  # POST /oauth/authorize - user submitted consent form
  # Boruta reads authorize params from query_params, so we merge body_params in.
  # This also supports Pushed Authorization Requests (PAR) where clients POST params.
  def authorize(%Plug.Conn{method: "POST"} = conn, _params) do
    conn = merge_body_into_query_params(conn)
    resource_owner = current_resource_owner(conn)
    Boruta.Oauth.authorize(conn, resource_owner, __MODULE__)
  end

  @impl Boruta.Oauth.AuthorizeApplication
  def preauthorize_success(conn, authorization) do
    scopes =
      authorization.scope
      |> String.split(" ", trim: true)

    conn
    |> put_view(GlossiaWeb.OAuth.AuthorizeHTML)
    |> render(:consent,
      client_name: authorization.client.name,
      scopes: scopes,
      params: conn.query_params
    )
  end

  @impl Boruta.Oauth.AuthorizeApplication
  def preauthorize_error(conn, error) do
    conn
    |> put_status(error.status)
    |> json(%{error: error.error, error_description: error.error_description})
  end

  @impl Boruta.Oauth.AuthorizeApplication
  def authorize_success(conn, response) do
    redirect(conn, external: Boruta.Oauth.AuthorizeResponse.redirect_to_url(response))
  end

  @impl Boruta.Oauth.AuthorizeApplication
  def authorize_error(conn, error) do
    conn
    |> put_status(error.status)
    |> json(%{error: error.error, error_description: error.error_description})
  end

  defp merge_body_into_query_params(conn) do
    merged = Map.merge(conn.query_params, conn.body_params)
    %{conn | query_params: merged}
  end

  defp current_resource_owner(conn) do
    user = conn.assigns[:current_user]

    %Boruta.Oauth.ResourceOwner{
      sub: user.id,
      username: user.email
    }
  end
end
