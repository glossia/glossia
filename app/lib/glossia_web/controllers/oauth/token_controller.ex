defmodule GlossiaWeb.OAuth.TokenController do
  use GlossiaWeb, :controller

  @behaviour Boruta.Oauth.TokenApplication

  plug GlossiaWeb.Plugs.RateLimit,
    key_prefix: "oauth_token",
    scale: :timer.minutes(1),
    limit: 30,
    by: :ip

  def token(%Plug.Conn{} = conn, _params) do
    Boruta.Oauth.token(conn, __MODULE__)
  end

  @impl Boruta.Oauth.TokenApplication
  def token_success(conn, %Boruta.Oauth.TokenResponse{} = response) do
    body = %{
      access_token: response.access_token,
      token_type: response.token_type,
      expires_in: response.expires_in
    }

    body =
      if response.refresh_token,
        do: Map.put(body, :refresh_token, response.refresh_token),
        else: body

    body =
      if response.id_token,
        do: Map.put(body, :id_token, response.id_token),
        else: body

    conn
    |> put_status(:ok)
    |> json(body)
  end

  @impl Boruta.Oauth.TokenApplication
  def token_error(conn, error) do
    conn
    |> put_status(error.status)
    |> json(%{error: error.error, error_description: error.error_description})
  end
end
