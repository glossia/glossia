defmodule Glossia.TranslationSessions.ContinuousTranslationWorker do
  @moduledoc """
  Coordinates a translation after a commit reaches a project's default branch.

  The webhook only persists this job. Before replacing an active translation,
  the worker asks GitHub for the current branch head so a delayed webhook can
  never move translation work back to an older commit.
  """

  use Oban.Worker, queue: :default, max_attempts: 5

  require Logger

  alias Glossia.Github
  alias Glossia.Projects
  alias Glossia.TranslationSessions

  @impl Oban.Worker
  def perform(%Oban.Job{
        args:
          %{
            "project_id" => project_id,
            "commit_sha" => commit_sha,
            "source_language" => source_language,
            "target_languages" => target_languages
          } = args
      }) do
    case Projects.get_project_by_id(project_id) do
      nil ->
        :ok

      project ->
        attrs = %{
          commit_sha: commit_sha,
          commit_message: args["commit_message"],
          source_language: source_language,
          target_languages: target_languages
        }

        coordinate(project, attrs)
    end
  end

  defp coordinate(project, %{commit_sha: commit_sha} = attrs) do
    with {:ok, token} <- github_token(project) do
      validate = fn -> validate_current_commit(project, commit_sha, token) end

      case TranslationSessions.start_continuous_session(project, attrs, validate: validate) do
        {:ok, _session} ->
          :ok

        {:ignored, :stale_push} ->
          Logger.debug("Ignoring stale default branch push",
            project_id: project.id,
            pushed_commit_sha: commit_sha
          )

          :ok

        {:error, reason} ->
          {:error, reason}
      end
    end
  end

  defp validate_current_commit(project, commit_sha, token) do
    with {:ok, ref} <-
           Github.Client.get_ref(
             project.github_repo_full_name,
             "heads/#{project.github_repo_default_branch || "main"}",
             token
           ),
         current_sha when is_binary(current_sha) <- get_in(ref, ["object", "sha"]) do
      if current_sha == commit_sha do
        :ok
      else
        classify_branch_mismatch(project, commit_sha, current_sha, token)
      end
    else
      nil -> {:error, :invalid_github_response}
      {:error, reason} -> {:error, reason}
    end
  end

  defp classify_branch_mismatch(project, pushed_sha, current_sha, token) do
    case Github.Client.compare_commits(
           project.github_repo_full_name,
           pushed_sha,
           current_sha,
           token
         ) do
      {:ok, %{"status" => status}} when status in ["ahead", "identical"] ->
        {:ignore, :stale_push}

      {:ok, %{"status" => status}} when status in ["behind", "diverged"] ->
        {:error, :default_branch_not_visible_yet}

      {:ok, _response} ->
        {:error, :invalid_github_response}

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp github_token(%{github_installation: nil}), do: {:ok, nil}

  defp github_token(project) do
    case Github.App.installation_token(project.github_installation.github_installation_id) do
      {:error, :not_configured} -> {:ok, nil}
      result -> result
    end
  end
end
