defmodule GlossiaWeb.OAuth.RegisterController do
  use GlossiaWeb, :controller

  @behaviour Boruta.Openid.DynamicRegistrationApplication
  alias Glossia.ChangesetErrors

  plug GlossiaWeb.Plugs.RateLimit,
    key_prefix: "oauth_register",
    scale: :timer.minutes(1),
    limit: 5,
    by: :ip

  @allowed_keys ~w(client_name redirect_uris grant_types token_endpoint_auth_method jwks jwks_uri logo_uri)

  def register(%Plug.Conn{body_params: registration_params} = conn, _params) do
    registration_params =
      registration_params
      |> Map.take(@allowed_keys)
      |> Map.new(fn {k, v} -> {String.to_atom(k), v} end)
      |> normalize_auth_method()
      |> Map.put(:pkce, true)

    Boruta.Openid.register_client(conn, registration_params, __MODULE__)
  end

  @impl Boruta.Openid.DynamicRegistrationApplication
  def client_registered(conn, %Boruta.Oauth.Client{} = client) do
    body = %{
      client_id: client.id,
      client_secret: client.secret,
      redirect_uris: client.redirect_uris,
      grant_types: client.supported_grant_types,
      token_endpoint_auth_method:
        case client.token_endpoint_auth_methods do
          [method | _] -> method
          _ -> "client_secret_basic"
        end
    }

    conn
    |> put_status(:created)
    |> json(body)
  end

  # Boruta doesn't support "none" as an auth method. Public clients (like Codex)
  # send "none" per RFC 7591. We drop it so Boruta uses its default methods,
  # which is fine since PKCE enforces proof-of-possession anyway.
  defp normalize_auth_method(%{token_endpoint_auth_method: "none"} = params),
    do: Map.delete(params, :token_endpoint_auth_method)

  defp normalize_auth_method(params), do: params

  @impl Boruta.Openid.DynamicRegistrationApplication
  def registration_failure(conn, changeset) do
    errors = ChangesetErrors.to_map(changeset)

    conn
    |> put_status(:bad_request)
    |> json(%{error: "invalid_client_metadata", error_description: errors})
  end
end
