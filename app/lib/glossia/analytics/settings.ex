defmodule Glossia.Analytics.Settings do
  @moduledoc """
  Reads and writes analytics project settings.

  `fetch_for_collection/1` resolves the site domain declared in the install
  snippet to the project id and its target languages (used to compute the
  localization gap at ingestion time), backed by `SettingsCache` so the hot path
  does not hit Postgres on every event. Only **verified** projects are
  returned; an unverified domain is treated as unknown so the SDK can never
  attribute events to a project whose owner has not proven control of the
  domain.
  """

  alias Glossia.Analytics.ProjectSettings
  alias Glossia.Analytics.SettingsCache
  alias Glossia.Analytics.Verification
  alias Glossia.Repo

  import Ecto.Query

  @doc """
  Returns the analytics settings row for a project, or `nil`.
  """
  def get_for_project(project_id) do
    Repo.get_by(ProjectSettings, project_id: project_id)
  end

  @doc """
  Resolves a domain to a project, only if that project is verified and
  enabled. Unverified domains return `nil` so the controller can keep its
  single "unknown domain" silent-202 path.
  """
  def fetch_for_collection(domain) when is_binary(domain) do
    domain = ProjectSettings.normalize_domain(domain)

    if domain == "" do
      nil
    else
      case SettingsCache.get(domain) do
        :miss ->
          case query(domain) do
            nil -> nil
            entry -> SettingsCache.put(domain, entry)
          end

        entry ->
          entry
      end
    end
  end

  defp query(domain) do
    from(s in ProjectSettings,
      join: p in assoc(s, :project),
      where:
        s.domain == ^domain and s.enabled == true and
          not is_nil(s.verified_at),
      select: %{
        project_id: p.id,
        target_languages: p.setup_target_languages,
        enabled: s.enabled
      }
    )
    |> Repo.one()
  end

  @doc """
  Creates or updates the analytics settings for a project. Invalidates the
  domain cache so a changed domain takes effect promptly.
  """
  def upsert_for_project(project_id, attrs) do
    settings = get_for_project(project_id) || %ProjectSettings{}
    previous_domain = Map.get(settings, :domain)

    result =
      settings
      |> ProjectSettings.changeset(Map.put(attrs, :project_id, project_id))
      |> Repo.insert_or_update()

    case result do
      {:ok, saved} ->
        if previous_domain, do: SettingsCache.delete(previous_domain)
        SettingsCache.delete(saved.domain)
        {:ok, saved}

      error ->
        error
    end
  end

  @doc """
  Re-runs the domain-ownership check for a project's settings. Returns
  `{:ok, settings}` with `verified_at` populated on success, or
  `{:ok, settings}` unchanged on failure (the operator can retry). Invalidates
  the domain cache so a freshly-verified project starts collecting immediately.
  """
  def verify_for_project(project_id) do
    case get_for_project(project_id) do
      nil ->
        {:error, :not_found}

      %ProjectSettings{domain: nil} ->
        {:error, :no_domain}

      %ProjectSettings{} = settings ->
        case Verification.verify(settings.domain, settings.verification_token) do
          :ok ->
            now = DateTime.utc_now() |> DateTime.truncate(:microsecond)

            case settings
                 |> Ecto.Changeset.change(%{verified_at: now})
                 |> Repo.update() do
              {:ok, updated} ->
                SettingsCache.delete(updated.domain)
                {:ok, updated}

              error ->
                error
            end

          :error ->
            {:ok, settings}
        end
    end
  end
end
