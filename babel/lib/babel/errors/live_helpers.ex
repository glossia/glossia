defmodule Babel.Errors.LiveHelpers do
  @moduledoc """
  Helpers shared by the `BabelWeb.ErrorsLive.*` modules.

  Babel is an internal operations platform fronted by Pomerium — its
  `Babel.Accounts.Account` is an operator identity, not an organization
  member. The errors subsystem is nevertheless scoped by
  `Babel.Organizations.Organization` on disk, because the ingest DSN
  belongs to an organization.

  For the operator UI we surface a single organization at a time; this
  helper picks the earliest-created organization as that "current" one
  and, when the database has none, provisions a `Babel` organization so
  the LiveViews never render against nothing.
  """

  alias Babel.Organizations.Organization
  alias Babel.Repo

  import Ecto.Query

  @fallback_name "Babel"
  @fallback_website "https://babel.glossia.ai"
  @fallback_state "customer"

  @doc """
  Returns the current organization the errors dashboard should render
  for. Provisions the fallback organization if the table is empty so
  the operator UI never crashes on a fresh install.
  """
  def current_organization do
    Organization
    |> order_by([o], asc: o.inserted_at)
    |> limit(1)
    |> Repo.one()
    |> case do
      %Organization{} = organization -> organization
      nil -> ensure_fallback_organization()
    end
  end

  defp ensure_fallback_organization do
    %Organization{}
    |> Organization.changeset(%{
      name: @fallback_name,
      website_url: @fallback_website,
      state: @fallback_state
    })
    |> Repo.insert(
      on_conflict: :nothing,
      conflict_target: :name,
      returning: true
    )
    |> case do
      {:ok, %Organization{id: nil}} ->
        Repo.one!(from o in Organization, where: o.name == ^@fallback_name)

      {:ok, %Organization{} = organization} ->
        organization

      {:error, _changeset} ->
        Repo.one!(from o in Organization, order_by: [asc: :inserted_at], limit: 1)
    end
  end
end
