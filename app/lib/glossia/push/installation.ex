defmodule Glossia.Push.Installation do
  @moduledoc """
  An opt-in installation, bound to one user and native OAuth client.
  The client UUID is also the registration ID. Retired IDs are permanent
  tombstones with neither an owner nor a provider token, fencing delayed PUTs.
  """
  use Glossia.Schema

  schema "push_installations" do
    belongs_to :user, Glossia.Accounts.User
    field :oauth_client_id, Ecto.UUID
    field :platform, :string
    field :environment, :string
    field :token, Glossia.Encrypted.Binary, redact: true
    field :token_digest, :binary, redact: true
    field :last_registered_at, :utc_datetime_usec
    field :retired_at, :utc_datetime_usec
    timestamps()
  end

  def digest(platform, environment, token),
    do: :crypto.hash(:sha256, [platform, ":", environment, ":", token])
end
