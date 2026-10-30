defmodule Glossia.Accounts.BrowserSession do
  @moduledoc "Server-side browser authentication and short-lived pending MFA challenges."
  use Ecto.Schema

  @primary_key {:token_hash, :binary, redact: true}
  @foreign_key_type Uniq.UUID
  schema "browser_sessions" do
    belongs_to :user, Glossia.Accounts.User
    field :context, :string
    field :authentication_version, :integer
    field :authenticated_at, :utc_datetime_usec
    field :expires_at, :utc_datetime_usec
    field :mfa_verified_at, :utc_datetime_usec
    field :organization_sso, :string
  end
end
