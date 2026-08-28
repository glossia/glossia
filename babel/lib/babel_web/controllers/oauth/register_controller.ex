defmodule BabelWeb.OAuth.RegisterController do
  use BabelWeb, :controller

  @behaviour Boruta.Openid.DynamicRegistrationApplication

  @allowed_keys ~w(client_name redirect_uris)
  @supported_grant_types ["authorization_code", "refresh_token"]

  def register(%Plug.Conn{body_params: registration_params} = conn, _params) do
    case validated_redirect_uris(registration_params["redirect_uris"]) do
      {:ok, redirect_uris} ->
        registration_params =
          registration_params
          |> Map.take(@allowed_keys)
          |> client_attributes()
          |> Map.put(:redirect_uris, redirect_uris)
          |> Map.put(:supported_grant_types, @supported_grant_types)
          |> Map.put(:pkce, true)
          |> Map.put(:confidential, false)
          |> Map.put(:public_refresh_token, true)
          |> Map.put(:token_endpoint_auth_methods, [])

        Boruta.Openid.register_client(conn, registration_params, __MODULE__)

      {:error, description} ->
        registration_error(conn, description)
    end
  end

  @impl Boruta.Openid.DynamicRegistrationApplication
  def client_registered(conn, %Boruta.Oauth.Client{} = client) do
    conn
    |> put_status(:created)
    |> json(%{
      client_id: client.id,
      redirect_uris: client.redirect_uris,
      grant_types: client.supported_grant_types,
      token_endpoint_auth_method: "none"
    })
  end

  @impl Boruta.Openid.DynamicRegistrationApplication
  def registration_failure(conn, changeset) do
    errors =
      Ecto.Changeset.traverse_errors(changeset, fn {message, options} ->
        Enum.reduce(options, message, fn {key, value}, message ->
          String.replace(message, "%{#{key}}", to_string(value))
        end)
      end)

    conn
    |> put_status(:bad_request)
    |> json(%{error: "invalid_client_metadata", error_description: errors})
  end

  defp validated_redirect_uris(redirect_uris)
       when is_list(redirect_uris) and redirect_uris != [] do
    if Enum.all?(redirect_uris, &valid_redirect_uri?/1) do
      {:ok, redirect_uris}
    else
      {:error, "redirect_uris must use HTTPS or a loopback HTTP address."}
    end
  end

  defp validated_redirect_uris(_redirect_uris), do: {:error, "redirect_uris is required."}

  defp client_attributes(registration_params) do
    Map.new(registration_params, fn
      {"client_name", value} -> {:client_name, value}
      {"redirect_uris", value} -> {:redirect_uris, value}
    end)
  end

  defp valid_redirect_uri?(redirect_uri) when is_binary(redirect_uri) do
    case URI.parse(redirect_uri) do
      %URI{scheme: "https", host: host, fragment: nil} when is_binary(host) ->
        true

      %URI{scheme: "http", host: host, fragment: nil}
      when host in ["127.0.0.1", "::1", "localhost"] ->
        true

      _ ->
        false
    end
  end

  defp valid_redirect_uri?(_redirect_uri), do: false

  defp registration_error(conn, description) do
    conn
    |> put_status(:bad_request)
    |> json(%{error: "invalid_client_metadata", error_description: description})
  end
end
