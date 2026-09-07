defmodule Glossia.Github.DevelopmentRepositories do
  @moduledoc false

  def list do
    if Application.get_env(:glossia, :dev_routes, false) do
      local_remotes_dir()
      |> repository_git_directories()
      |> Enum.map(&repository/1)
      |> Enum.sort_by(& &1["full_name"])
    else
      []
    end
  end

  defp local_remotes_dir do
    :glossia
    |> Application.get_env(Glossia.Translations, [])
    |> Keyword.get(:local_remotes_dir)
  end

  defp repository_git_directories(dir) when is_binary(dir) and dir != "" do
    dir
    |> Path.expand()
    |> Path.join("*/*/.git")
    |> Path.wildcard(match_dot: true)
  end

  defp repository_git_directories(_dir), do: []

  defp repository(git_dir) do
    repository_dir = Path.dirname(git_dir)
    full_name = repository_dir |> Path.split() |> Enum.take(-2) |> Path.join()
    name = Path.basename(repository_dir)
    [owner, _name] = String.split(full_name, "/", parts: 2)

    %{
      "id" => repository_id(full_name),
      "full_name" => full_name,
      "name" => name,
      "default_branch" => default_branch(git_dir),
      "description" => "Local development repository",
      "language" => nil,
      "development" => true,
      "owner" => %{"login" => owner}
    }
  end

  defp default_branch(git_dir) do
    case File.read(Path.join(git_dir, "HEAD")) do
      {:ok, "ref: refs/heads/" <> branch} -> String.trim(branch)
      _ -> "main"
    end
  end

  defp repository_id(full_name) do
    <<id::unsigned-integer-size(63), _rest::bits>> = :crypto.hash(:sha256, full_name)
    id
  end
end
