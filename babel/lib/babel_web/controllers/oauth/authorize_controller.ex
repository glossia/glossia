defmodule BabelWeb.OAuth.AuthorizeController do
  use BabelWeb, :controller

  @behaviour Boruta.Oauth.AuthorizeApplication

  alias Babel.Accounts.Account
  alias Boruta.Oauth.AuthorizeResponse

  def authorize(%Plug.Conn{method: "GET"} = conn, _params) do
    case conn.query_params["request_uri"] do
      nil -> preauthorize(conn)
      _request_uri -> invalid_request(conn)
    end
  end

  def authorize(%Plug.Conn{method: "POST"} = conn, _params) do
    case conn.body_params["request_uri"] || conn.query_params["request_uri"] do
      nil -> authorize_request(conn)
      _request_uri -> invalid_request(conn)
    end
  end

  @impl Boruta.Oauth.AuthorizeApplication
  def preauthorize_success(conn, authorization) do
    conn
    |> put_view(BabelWeb.OAuth.AuthorizeHTML)
    |> render(:consent,
      client_name: authorization.client.name,
      scopes: String.split(authorization.scope, " ", trim: true),
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
    redirect(conn, external: AuthorizeResponse.redirect_to_url(response))
  end

  @impl Boruta.Oauth.AuthorizeApplication
  def authorize_error(conn, error) do
    conn
    |> put_status(error.status)
    |> json(%{error: error.error, error_description: error.error_description})
  end

  defp resource_owner(account) do
    %Boruta.Oauth.ResourceOwner{
      sub: Integer.to_string(account.id),
      username: account.email
    }
  end

  defp preauthorize(conn) do
    case conn.assigns[:current_account] do
      %Account{} = account -> Boruta.Oauth.preauthorize(conn, resource_owner(account), __MODULE__)
      _account -> unauthorized(conn)
    end
  end

  defp authorize_request(conn) do
    case conn.assigns[:current_account] do
      %Account{} = account ->
        conn
        |> merge_body_into_query_params()
        |> Boruta.Oauth.authorize(resource_owner(account), __MODULE__)

      _account ->
        unauthorized(conn)
    end
  end

  defp merge_body_into_query_params(conn) do
    %{conn | query_params: Map.merge(conn.query_params, conn.body_params)}
  end

  defp unauthorized(conn) do
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(:unauthorized, JSON.encode!(%{error: "unauthorized"}))
    |> halt()
  end

  defp invalid_request(conn) do
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(:bad_request, JSON.encode!(%{error: "invalid_request"}))
    |> halt()
  end
end
