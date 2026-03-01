defmodule Glossia.Repo.Migrations.EnsureFirstPartyMobileOauthClient do
  use Ecto.Migration

  def up do
    execute("""
    UPDATE oauth_clients
    SET metadata = '{"first_party":true,"authorization_code_pkce":true,"device_flow":true,"platform":"mobile","app":"glossia-mobile"}'::jsonb,
        redirect_uris = ARRAY[
          'glossia://oauth/callback',
          'https://glossia.ai/oauth/callback',
          'exp://localhost:8081/--/oauth/callback',
          'exp://127.0.0.1:8081/--/oauth/callback',
          'https://glossia.ai/oauth/device'
        ]::varchar[],
        updated_at = NOW()
    WHERE id = '6b7a2d2b-5f2a-4a57-9ea5-31a4d5b0c5f9'
    """)
  end

  def down, do: :ok
end
