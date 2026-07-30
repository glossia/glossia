defmodule Glossia.Analytics.ProjectSettings do
  @moduledoc """
  Per-project analytics configuration: the site `domain` that identifies the
  project and an enable flag. One row per project.

  Following Plausible's model, collection is identified by the domain declared in
  the install snippet (`data-domain="example.com"`) rather than a secret key. The
  domain is public and unique per project; abuse is mitigated by rate limiting
  and (later) an origin allowlist. The visitor-hash salt is a single server-held
  secret, never a per-project credential.
  """

  use Glossia.Schema
  import Ecto.Changeset

  @type t :: %__MODULE__{}

  schema "analytics_project_settings" do
    field :domain, :string
    field :enabled, :boolean, default: true
    belongs_to :project, Glossia.Accounts.Project

    timestamps(type: :utc_datetime_usec)
  end

  @doc """
  Normalizes a domain for storage and lookup so the install snippet and the
  registered project resolve to the same value: strips the scheme, `www.`, any
  path/port, and lowercases. Returns `""` for blank input.

      iex> normalize_domain("https://WWW.Example.com/blog")
      "example.com"
  """
  @spec normalize_domain(String.t() | nil) :: String.t()
  def normalize_domain(nil), do: ""

  def normalize_domain(domain) when is_binary(domain) do
    domain
    |> String.trim()
    |> String.downcase()
    |> String.replace(~r{^[a-z][a-z0-9+.-]*://}, "")
    |> String.split("/", parts: 2)
    |> List.first()
    |> String.split(":", parts: 2)
    |> List.first()
    |> String.replace_prefix("www.", "")
  end

  def changeset(settings, attrs) do
    settings
    |> cast(attrs, [:domain, :enabled, :project_id])
    |> update_change(:domain, &normalize_domain/1)
    |> validate_required([:domain, :project_id])
    |> validate_length(:domain, min: 1, max: 253)
    |> unique_constraint(:domain)
    |> unique_constraint(:project_id)
  end
end
