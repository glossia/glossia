defmodule BabelWeb.OAuth.TokenController do
  use BabelWeb, :controller

  @behaviour Boruta.Oauth.TokenApplication

  def token(conn, _params), do: Boruta.Oauth.token(conn, __MODULE__)

  @impl Boruta.Oauth.TokenApplication
  def token_success(conn, %Boruta.Oauth.TokenResponse{} = response) do
    response_body = %{
      access_token: response.access_token,
      token_type: response.token_type,
      expires_in: response.expires_in
    }

    response_body =
      if response.refresh_token,
        do: Map.put(response_body, :refresh_token, response.refresh_token),
        else: response_body

    json(conn, response_body)
  end

  @impl Boruta.Oauth.TokenApplication
  def token_error(conn, error) do
    conn
    |> put_status(error.status)
    |> json(%{error: error.error, error_description: error.error_description})
  end
end
