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
  path/port/query/fragment, and lowercases. Returns `""` for blank input.

      iex> normalize_domain("https://WWW.Example.com/blog")
      "example.com"
  """
  @spec normalize_domain(String.t() | nil) :: String.t()
  def normalize_domain(nil), do: ""

  def normalize_domain(domain) when is_binary(domain) do
    domain
    |> String.trim()
    |> String.downcase()
    |> ensure_scheme()
    |> URI.parse()
    |> extract_host()
    |> String.replace_prefix("www.", "")
  end

  # `URI.parse/1` only treats the input as a URI when a scheme is present, so
  # prepend one to bare hosts like "example.com" or "www.example.com" before
  # parsing. The caller has already downcased the input, so the prefix match
  # is case-sensitive.
  defp ensure_scheme("http://" <> rest), do: "http://" <> rest
  defp ensure_scheme("https://" <> rest), do: "https://" <> rest
  defp ensure_scheme(domain), do: "https://" <> domain

  defp extract_host(%URI{host: host}) when is_binary(host) and host != "", do: host
  defp extract_host(_), do: ""

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
