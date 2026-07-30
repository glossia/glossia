defmodule Glossia.Analytics.Settings do
  @moduledoc """
  Reads analytics project settings for collection.

  `fetch_for_collection/1` resolves a public collection key to the project id and
  its target languages (used to compute the localization gap at ingestion time),
  backed by `SettingsCache` so the hot path does not hit Postgres on every event.
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
  def fetch_for_collection(public_key) when is_binary(public_key) do
    case SettingsCache.get(public_key) do
      :miss ->
        case query(public_key) do
          nil -> nil
          entry -> SettingsCache.put(public_key, entry)
        end

      entry ->
        entry
    end
  end

  defp query(public_key) do
    from(s in ProjectSettings,
      join: p in assoc(s, :project),
      where: s.public_key == ^public_key and s.enabled == true,
      select: %{
        project_id: p.id,
        target_languages: p.setup_target_languages,
        enabled: s.enabled
      }
    )
    |> Repo.one()
  end

  @doc """
  Creates (or returns) analytics settings for a project, generating a public key.
  """
  def ensure_for_project(project_id) do
    case Repo.get_by(ProjectSettings, project_id: project_id) do
      nil ->
        %ProjectSettings{}
        |> ProjectSettings.changeset(%{
          project_id: project_id,
          public_key: ProjectSettings.generate_key(),
          enabled: true
        })
        |> Repo.insert()

      settings ->
        {:ok, settings}
    end
  end
end
