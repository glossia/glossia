defmodule Glossia.Analytics.Settings do
  @moduledoc """
  Reads and writes analytics project settings.

  `fetch_for_collection/1` resolves the site domain declared in the install
  snippet to the project id and its target languages (used to compute the
  localization gap at ingestion time), backed by `SettingsCache` so the hot path
  does not hit Postgres on every event.
  """

  alias Glossia.Analytics.ProjectSettings
  alias Glossia.Analytics.SettingsCache
  alias Glossia.Repo

  import Ecto.Query

  @type collection_target :: %{
          project_id: binary(),
          target_languages: [String.t()],
          enabled: boolean()
        }

  @spec fetch_for_collection(String.t()) :: collection_target() | nil
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
      where: s.domain == ^domain and s.enabled == true,
      select: %{
        project_id: p.id,
        target_languages: p.setup_target_languages,
        enabled: s.enabled
      }
    )
    |> Repo.one()
  end

  @doc """
  Returns the analytics settings row for a project, or `nil`.
  """
  @spec get_for_project(binary()) :: ProjectSettings.t() | nil
  def get_for_project(project_id) do
    Repo.get_by(ProjectSettings, project_id: project_id)
  end

  @doc """
  Creates or updates the analytics settings for a project. Invalidates the
  domain cache so a changed domain takes effect promptly.
  """
  @spec upsert_for_project(binary(), map()) ::
          {:ok, ProjectSettings.t()} | {:error, Ecto.Changeset.t()}
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
end
