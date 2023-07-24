defmodule Glossia.Translations.Translate do
  @moduledoc """
  A translate build represents a translation job that's being run in a virtualized environment.
  Locally we use Docker when present, and in production we use Google Cloud Build.
  """

  # Modules
  require Logger
  use Oban.Worker, queue: :translations, max_attempts: 1
  alias Glossia.Translations.Translation
  alias Glossia.Repo

  # Impl: Oban.Worker

  @impl Oban.Worker
  def perform(%Oban.Job{
        args: %{
          "commit_sha" => commit_sha,
          "repository_id" => repository_id,
          "vcs" => vcs
        }
      }) do
    vcs = String.to_atom(vcs)
    project = Glossia.Projects.find_project_by_repository(repository_id, vcs)
    translate(commit_sha: commit_sha, project: project)
    :ok
  end

  def translate(commit_sha: commit_sha, project: %Glossia.Projects.Project{} = project) do
    Logger.info(
      "Translating project #{project.id} for commit #{commit_sha} in repository #{project.repository_id}"
    )

    translation = Repo.get_by(Translation, commit_sha: commit_sha, project_id: project.id)
    translate(commit_sha: commit_sha, project: project, translation: translation)
    :ok
  end

  def translate(commit_sha: _, project: nil) do
    # Noop
    :ok
  end

  def translate(
        commit_sha: _,
        project: %Glossia.Projects.Project{} = _,
        translation: %Glossia.Translations.Translation{} = _
      ) do
    # Noop since a translation already exists
    :ok
  end

  def translate(
        commit_sha: commit_sha,
        project: %Glossia.Projects.Project{} = project,
        translation: nil
      ) do
    translation =
      Repo.insert!(
        Translation.changeset(%Translation{}, %{
          commit_sha: commit_sha,
          project_id: project.id,
          repository_id: project.repository_id,
          vcs: project.vcs
        })
      )

    commit_status_attrs = [
      commit_sha: commit_sha,
      repository_id: project.repository_id,
      vcs: project.vcs
    ]

    commit_status_attrs
    |> Keyword.put_new(:state, "pending")
    |> Keyword.put_new(:description, "Translating")
    |> create_commit_status()

    Glossia.VM.translate(translation_id: translation.id)

    commit_status_attrs
    |> Keyword.put_new(:state, "success")
    |> Keyword.put_new(:description, "Translated")
    |> create_commit_status()

    :ok
  end

  defp create_commit_status(
         description: description,
         state: state,
         commit_sha: commit_sha,
         repository_id: repository_id,
         vcs: vcs
       ) do
    context =
      case Application.get_env(:glossia, :env) do
        :prod -> "Glossia"
        _ -> "Glossia (#{Application.get_env(:glossia, :env)})"
      end

    Glossia.VCS.create_commit_status(
      vcs: vcs,
      commit_sha: commit_sha,
      repository_id: repository_id,
      state: state,
      target_url: "https://glossia.ai",
      context: context,
      description: description
    )
  end
end
