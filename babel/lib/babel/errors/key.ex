defmodule Babel.Errors.Key do
  @moduledoc """
  A Data Source Name ([DSN](https://docs.sentry.io/product/sentry-basics/dsn-explainer/))
  minted for an organization. The `public_key` is the identifier SDKs
  send in the `X-Sentry-Auth` header (or `sentry_key` query parameter).
  The `secret_key` is a Sentry legacy field kept for compatibility with
  older SDKs; modern SDKs ignore it.

  Each organization can have multiple keys (e.g. one per environment or
  per service), each with its own `dsn_project_id` — the numeric segment
  Sentry SDKs put in the DSN URL path, and the value the ingest endpoint
  uses to look the key up on the way in.
  """

  use Ecto.Schema

  import Ecto.Changeset

  alias Babel.Organizations.Organization

  @primary_key {:id, :binary_id, autogenerate: true}

  schema "errors_project_keys" do
    field :dsn_project_id, :integer, read_after_writes: true
    field :public_key, :string
    field :secret_key, :string
    field :name, :string, default: "default"
    field :last_used_at, :utc_datetime_usec

    belongs_to :organization, Organization

    timestamps(type: :utc_datetime)
  end

  def changeset(key, attrs) do
    key
    |> cast(attrs, [
      :organization_id,
      :public_key,
      :secret_key,
      :name
    ])
    |> validate_required([:organization_id, :public_key, :name])
    |> validate_length(:public_key, is: 32)
    |> validate_length(:secret_key, is: 32)
    |> validate_length(:name, min: 1, max: 100)
    |> unique_constraint(:public_key)
    |> unique_constraint([:organization_id, :name],
      name: :errors_project_keys_organization_id_name_index,
      message: "organization already has a key with this name"
    )
  end

  @doc """
  Generates a random 32-character hex key suitable for the `public_key`
  or `secret_key` field.
  """
  def generate_key do
    16
    |> :crypto.strong_rand_bytes()
    |> Base.encode16(case: :lower)
  end

  @doc """
  Renders the DSN string SDKs consume, given a host built from the
  endpoint URL and the numeric project id required by Sentry clients.
  """
  def dsn(%__MODULE__{public_key: public_key, dsn_project_id: project_id}, endpoint_url)
      when is_binary(endpoint_url) do
    uri = URI.parse(endpoint_url)
    scheme = uri.scheme || "https"
    host = uri.host
    port = if uri.port in [nil, 80, 443], do: "", else: ":#{uri.port}"
    "#{scheme}://#{public_key}@#{host}#{port}/#{project_id}"
  end
end
