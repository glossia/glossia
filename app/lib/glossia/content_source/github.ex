defmodule Glossia.ContentSource.Github do
  @moduledoc false
  @behaviour Glossia.ContentSource

  @impl true
  def list_commits(project, opts \\ []) do
    per_page = Keyword.get(opts, :per_page, 30)

    with {:ok, installation} <- load_installation(project),
         {:ok, token} <-
           Glossia.Github.App.installation_token(installation.github_installation_id),
         {:ok, raw_commits} when is_list(raw_commits) <-
           Glossia.Github.Client.list_commits(project.github_repo_full_name, token,
             per_page: per_page
           ) do
      {:ok, Enum.map(raw_commits, &normalize_commit(&1, project.github_repo_full_name))}
    else
      {:ok, _unexpected} -> {:error, :unexpected_response}
      {:error, _} = err -> err
    end
  end

  defp load_installation(project) do
    if project.github_installation_id do
      installation =
        Glossia.Repo.preload(project, :github_installation).github_installation

      {:ok, installation}
    else
      {:error, :no_github_installation}
    end
  end

  defp normalize_commit(raw, repo_full_name) do
    commit = raw["commit"] || %{}
    author = raw["author"] || commit["author"] || %{}

    %{
      sha: raw["sha"] || "",
      short_sha: String.slice(raw["sha"] || "", 0, 7),
      message: commit["message"] || "",
      author_name: author["login"] || get_in(commit, ["author", "name"]) || "",
      author_avatar_url: author["avatar_url"],
      date: parse_commit_date(get_in(commit, ["author", "date"])),
      url: "https://github.com/#{repo_full_name}/commit/#{raw["sha"]}"
    }
  end

  defp parse_commit_date(nil), do: nil

  defp parse_commit_date(date_string) do
    case DateTime.from_iso8601(date_string) do
      {:ok, dt, _offset} -> dt
      _ -> nil
    end
  end
end
