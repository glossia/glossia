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

  schema "analytics_project_settings" do
    field :domain, :string
    field :enabled, :boolean, default: true
    field :verification_token, :string
    field :verified_at, :utc_datetime_usec
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
    |> put_verification_token()
    |> reset_verification_on_domain_change()
  end

  # On insert, mint a fresh token. On update, leave the existing token alone
  # so a re-save of the same settings doesn't invalidate the user's pending
  # DNS / meta-tag proof.
  defp put_verification_token(changeset) do
    if changeset.data.__meta__.state == :built and
         (changeset.data.verification_token in [nil, ""] or
            get_change(changeset, :verification_token)) do
      put_change(changeset, :verification_token, generate_token())
    else
      changeset
    end
  end

  # If the domain is being changed, the existing token is meaningless for the
  # new domain and the previously-verified status no longer applies. Clear
  # both so the operator has to prove ownership of the new domain.
  defp reset_verification_on_domain_change(changeset) do
    case {get_change(changeset, :domain), changeset.data.domain} do
      {new_domain, previous_domain} when new_domain != nil and new_domain != previous_domain ->
        changeset
        |> put_change(:verification_token, generate_token())
        |> put_change(:verified_at, nil)

      _ ->
        changeset
    end
  end

  defp generate_token do
    :crypto.strong_rand_bytes(32) |> Base.encode16(case: :lower)
  end
end
