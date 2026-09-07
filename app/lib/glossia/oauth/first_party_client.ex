defmodule Glossia.OAuth.FirstPartyClient do
  @moduledoc false

  alias Boruta.Ecto.Admin
  alias Boruta.Ecto.Client
  alias Glossia.Repo

  @mobile_client_id "6b7a2d2b-5f2a-4a57-9ea5-31a4d5b0c5f9"
  @mobile_client_name "Glossia Mobile"
  @mobile_redirect_uris [
    "glossia://oauth/callback",
    "https://glossia.ai/oauth/callback",
    "exp://localhost:8081/--/oauth/callback",
    "exp://127.0.0.1:8081/--/oauth/callback",
    "exp://localhost:19000/--/oauth/callback",
    "exp://127.0.0.1:19000/--/oauth/callback",
    "https://glossia.ai/oauth/device"
  ]

  def mobile_client_id, do: @mobile_client_id
  def mobile_client_name, do: @mobile_client_name
  def mobile_redirect_uris, do: @mobile_redirect_uris

  def mobile_client_attrs do
    %{
      id: @mobile_client_id,
      name: @mobile_client_name,
      redirect_uris: @mobile_redirect_uris,
      supported_grant_types: ["authorization_code", "refresh_token", "revoke"],
      authorize_scope: true,
      confidential: false,
      pkce: true,
      public_refresh_token: true,
      public_revoke: true,
      metadata: %{
        "first_party" => true,
        "authorization_code_pkce" => true,
        "device_flow" => true,
        "platform" => "mobile",
        "app" => "glossia-mobile"
      }
    }
  end

  def ensure_mobile_client do
    attrs = mobile_client_attrs()

    case Repo.get(Client, @mobile_client_id) do
      nil ->
        Admin.create_client(attrs)

      %Client{} = client ->
        Admin.update_client(client, attrs)
    end
  end
end
