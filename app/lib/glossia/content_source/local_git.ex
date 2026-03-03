defmodule Glossia.ContentSource.LocalGit do
  @moduledoc false
  @behaviour Glossia.ContentSource

  require Logger

  @impl true
  def list_commits(project, opts \\ []) do
    per_page = Keyword.get(opts, :per_page, 30)

    case repo_path(project) do
      {:ok, path} ->
        format = "%H%n%s%n%an%n%aI"

        case MuonTrap.cmd("git", [
               "-C",
               path,
               "log",
               "--format=#{format}",
               "--max-count=#{per_page}",
               "HEAD"
             ]) do
          {output, 0} ->
            {:ok, parse_log_output(output)}

          {error_output, code} ->
            Logger.warning(
              "git log failed for #{path} (exit #{code}): #{String.slice(error_output, 0, 200)}"
            )

            {:error, {:git_error, code}}
        end

      {:error, _} = err ->
        err
    end
  end

  defp repo_path(project) do
    relative = project.content_source_path

    if relative do
      path = Path.join([File.cwd!(), "fixtures", "repos", relative])

      if File.dir?(path) do
        {:ok, path}
      else
        {:error, {:repo_not_found, path}}
      end
    else
      {:error, :no_content_source_path}
    end
  end

  defp parse_log_output(output) do
    output
    |> String.trim()
    |> String.split("\n")
    |> Enum.chunk_every(4)
    |> Enum.filter(&(length(&1) == 4))
    |> Enum.map(fn [sha, message, author_name, date_string] ->
      %{
        sha: sha,
        short_sha: String.slice(sha, 0, 7),
        message: message,
        author_name: author_name,
        author_avatar_url: nil,
        date: parse_date(date_string),
        url: nil
      }
    end)
  end

  defp parse_date(date_string) do
    case DateTime.from_iso8601(date_string) do
      {:ok, dt, _offset} -> dt
      _ -> nil
    end
  end
end
