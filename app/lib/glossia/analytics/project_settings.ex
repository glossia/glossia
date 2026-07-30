defmodule Glossia.Analytics.ProjectSettings do
  @moduledoc """
  Per-project analytics configuration: a public collection key and an enable
  flag. One row per project.

  The `public_key` is non-secret (it ships in the customer's HTML) but unique per
  project; abuse is mitigated by rate limiting and (later) a domain allowlist.
  """

  use Glossia.Schema
  import Ecto.Changeset

  schema "analytics_project_settings" do
    field :public_key, :string
    field :enabled, :boolean, default: true
    belongs_to :project, Glossia.Accounts.Project

    timestamps(type: :utc_datetime_usec)
  end

  @doc """
  Generates a fresh, URL-safe public collection key, e.g. `pk_3xF9...`.
  """
  def generate_key do
    "pk_" <> Base.url_encode64(:crypto.strong_rand_bytes(18), padding: false)
  end

  def changeset(settings, attrs) do
    settings
    |> cast(attrs, [:public_key, :enabled, :project_id])
    |> validate_required([:public_key, :project_id])
    |> unique_constraint(:public_key)
    |> unique_constraint(:project_id)
  end
end
