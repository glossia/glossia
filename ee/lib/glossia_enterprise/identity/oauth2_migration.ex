defmodule GlossiaEnterprise.Identity.OAuth2Migration do
  @moduledoc false
  use Ecto.Migration

  def change do
    alter table(:organization_security_settings) do
      add :auth_authorize_url, :text
      add :auth_token_url, :text
      add :auth_userinfo_url, :text
    end
  end
end
