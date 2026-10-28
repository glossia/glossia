defmodule GlossiaEnterprise.Identity.SecuritySettings do
  @moduledoc false
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key false
  schema "organization_security_settings" do
    belongs_to :organization, Glossia.Accounts.Organization, type: Uniq.UUID, primary_key: true
    field :sso_enforced, :boolean, default: false
    field :auth_authorize_url, :string
    field :auth_token_url, :string
    field :auth_userinfo_url, :string
  end

  def changeset(settings, attrs, provider) do
    fields = [:auth_authorize_url, :auth_token_url, :auth_userinfo_url]
    changeset = cast(settings, attrs, fields)

    if provider == "oauth2" do
      Enum.reduce(fields, validate_required(changeset, fields), fn field, changeset ->
        validate_change(changeset, field, fn field, value ->
          if GlossiaEnterprise.Identity.OAuth2HTTP.valid_url?(value),
            do: [],
            else: [{field, "must be an HTTPS URL without credentials, query, or fragment"}]
        end)
      end)
    else
      Enum.reduce(fields, changeset, &put_change(&2, &1, nil))
    end
  end
end
