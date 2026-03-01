defmodule GlossiaWeb.OAuth.TokenController do
  use GlossiaWeb, :controller

  alias Boruta.ClientsAdapter
  alias Boruta.Oauth.Client
  alias Glossia.OAuth.DeviceFlow

  @behaviour Boruta.Oauth.TokenApplication
  @device_grant_type DeviceFlow.device_grant_type()

  plug GlossiaWeb.Plugs.RateLimit,
    key_prefix: "oauth_token",
    scale: :timer.minutes(1),
    limit: 30,
    by: [:ip, :client_id]

  def token(%Plug.Conn{} = conn, %{"grant_type" => @device_grant_type} = params) do
    with {:ok, client} <- authenticate_client(params),
         :ok <- DeviceFlow.ensure_first_party_device_client(client),
         device_code when is_binary(device_code) and device_code != "" <- params["device_code"],
         {:ok, response} <- DeviceFlow.exchange_device_code(client, device_code) do
      token_success(conn, response)
    else
      {:error, :invalid_client} ->
        oauth_error(conn, :unauthorized, "invalid_client", "Client authentication failed.")

      {:error, :unauthorized_client} ->
        oauth_error(
          conn,
          :bad_request,
          "unauthorized_client",
          "Client is not allowed to use the device flow."
        )

      {:error, :authorization_pending} ->
        oauth_error(
          conn,
          :bad_request,
          "authorization_pending",
          "User has not completed device authorization yet."
        )

      {:error, :slow_down} ->
        oauth_error(
          conn,
          :bad_request,
          "slow_down",
          "Slow down your polling frequency."
        )

      {:error, :access_denied} ->
        oauth_error(conn, :bad_request, "access_denied", "User denied the authorization request.")

      {:error, :expired_token} ->
        oauth_error(conn, :bad_request, "expired_token", "Device code has expired.")

      {:error, :invalid_grant} ->
        oauth_error(
          conn,
          :bad_request,
          "invalid_grant",
          "Device code is invalid or already used."
        )

      {:error, :server_error} ->
        oauth_error(conn, :internal_server_error, "server_error", "Could not issue token.")

      nil ->
        oauth_error(conn, :bad_request, "invalid_request", "Missing device_code parameter.")

      _ ->
        oauth_error(conn, :bad_request, "invalid_request", "Invalid device token request.")
    end
  end

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

  defp authenticate_client(%{"client_id" => client_id} = params) when is_binary(client_id) do
    client = ClientsAdapter.get_client(client_id)
    client_secret = Map.get(params, "client_secret")

    case client do
      %Client{} = client ->
        if client.confidential do
          case client_secret do
            secret when is_binary(secret) and secret != "" ->
              case Client.check_secret(client, secret) do
                :ok -> {:ok, client}
                _ -> {:error, :invalid_client}
              end

            _ ->
              {:error, :invalid_client}
          end
        else
          {:ok, client}
        end

      _ ->
        {:error, :invalid_client}
    end
  end

  defp authenticate_client(_params), do: {:error, :invalid_client}

  defp oauth_error(conn, status, error, description) do
    conn
    |> put_status(status)
    |> json(%{error: error, error_description: description})
  end
end
