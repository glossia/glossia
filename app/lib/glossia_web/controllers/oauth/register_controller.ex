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
    public? = not client.confidential and client.token_endpoint_auth_methods == []

    body = %{
      client_id: client.id,
      redirect_uris: client.redirect_uris,
      grant_types: client.supported_grant_types,
      token_endpoint_auth_method:
        if public? do
          "none"
        else
          List.first(client.token_endpoint_auth_methods) || "client_secret_basic"
        end
    }

    body = if public?, do: body, else: Map.put(body, :client_secret, client.secret)

    conn
    |> put_status(:created)
    |> json(body)
  end

  # Boruta 2.x represents public clients with flags rather than the RFC 7591
  # "none" method. Never give a public registration client_credentials grants.
  defp normalize_auth_method(%{token_endpoint_auth_method: "none"} = params) do
    params
    |> Map.delete(:token_endpoint_auth_method)
    |> Map.merge(%{
      confidential: false,
      token_endpoint_auth_methods: [],
      supported_grant_types: ["authorization_code", "refresh_token", "revoke"],
      authorize_scope: true,
      public_refresh_token: true,
      public_revoke: true
    })
  end

  defp normalize_auth_method(params), do: params

  @impl Boruta.Openid.DynamicRegistrationApplication
  def registration_failure(conn, changeset) do
    errors = ChangesetErrors.to_map(changeset)

    conn
    |> put_status(:bad_request)
    |> json(%{error: "invalid_client_metadata", error_description: errors})
  end
end
