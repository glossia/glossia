defmodule Glossia.Editor.Publisher do
  @moduledoc "Publishes a complete frozen draft group on one retry-safe branch."
  alias Glossia.Github.Client

  def check_bases(repository, files) do
    with {:ok, %{"object" => %{"sha" => base}}} <-
           Client.get_ref(
             repository.full_name,
             "heads/#{repository.default_branch}",
             repository.token
           ),
         {:ok, {_tree, entries}} <- tree(repository.full_name, base, repository.token) do
      verify_bases(entries, files)
    end
  end

  def publish(repository, files) do
    repo = repository.full_name
    token = repository.token
    branch = hd(files).branch
    [owner, _] = String.split(repo, "/", parts: 2)

    with {:ok, prs} <-
           Client.list_pull_requests(repo, token, head: "#{owner}:#{branch}", state: "all") do
      case prs do
        [pr | _] ->
          # PR discovery alone is not evidence that its branch still contains
          # our complete frozen manifest.
          with :ok <- verify_branch(repository, files), do: {:ok, pr}

        [] ->
          create(repository, files)
      end
    end
  end

  defp create(repository, files) do
    repo = repository.full_name
    token = repository.token

    with :ok <- ensure_branch(repository, files),
         {:ok, pr} <-
           Client.create_pull_request(
             repo,
             %{
               title: message(files),
               head: hd(files).branch,
               base: repository.default_branch,
               body:
                 "## What changed\n\n" <>
                   Enum.map_join(files, "\n", &"- Edits #{&1.path} (#{&1.locale}).") <>
                   "\n\n## Why\n\nManual content review by the project team.\n\n## Approach\n\nOnly the selected files are changed. All repository versions were checked before preparing the commit.\n\n## Validation\n\nReview the content and let the repository's checks run before merging."
             },
             token
           ) do
      {:ok, pr}
    end
  end

  defp ensure_branch(repository, files) do
    repo = repository.full_name
    token = repository.token

    case Client.get_ref(repo, "heads/#{hd(files).branch}", token) do
      {:ok, %{"object" => %{"sha" => sha}}} ->
        verify_commit(repository, files, sha)

      {:error, {:api_error, 404, _}} ->
        build_branch(repository, files)

      {:error, _} = error ->
        error
    end
  end

  defp verify_branch(repository, files) do
    with {:ok, %{"object" => %{"sha" => sha}}} <-
           Client.get_ref(repository.full_name, "heads/#{hd(files).branch}", repository.token) do
      verify_commit(repository, files, sha)
    end
  end

  defp verify_commit(repository, files, sha) do
    repo = repository.full_name
    token = repository.token

    # Our branch has exactly one commit on the verified base. Compare every
    # leaf, not only the selected paths, to reject injected/unrelated changes.
    with {:ok, %{"tree" => %{"sha" => tree_sha}, "parents" => [%{"sha" => base}]}} <-
           Client.get_commit(repo, sha, token),
         {:ok, entries} <- entries(repo, tree_sha, token),
         {:ok, {_base_tree, base_entries}} <- tree(repo, base, token),
         :ok <- verify_bases(base_entries, files),
         expected =
           Enum.reduce(files, leaves(base_entries), fn file, acc ->
             Map.put(acc, file.path, {"blob", file.mode, blob_sha(file.draft_content)})
           end),
         true <- leaves(entries) == expected do
      :ok
    else
      {:error, :base_changed} -> {:error, :repository_changed}
      {:error, _} = error -> error
      _ -> {:error, :repository_changed}
    end
  end

  defp leaves(entries) do
    entries
    |> Enum.reject(&(&1["type"] == "tree"))
    |> Map.new(&{&1["path"], {&1["type"], &1["mode"], &1["sha"]}})
  end

  defp build_branch(repository, files) do
    repo = repository.full_name
    token = repository.token

    with {:ok, %{"object" => %{"sha" => base}}} <-
           Client.get_ref(repo, "heads/#{repository.default_branch}", token),
         {:ok, {base_tree, entries}} <- tree(repo, base, token),
         :ok <- verify_bases(entries, files),
         {:ok, %{"sha" => tree_sha}} <-
           Client.create_tree(
             repo,
             %{
               base_tree: base_tree,
               tree:
                 Enum.map(files, fn file ->
                   %{path: file.path, mode: file.mode, type: "blob", content: file.draft_content}
                 end)
             },
             token
           ),
         {:ok, %{"sha" => commit}} <-
           Client.create_commit(
             repo,
             %{
               message: message(files),
               tree: tree_sha,
               parents: [base]
             },
             token
           ),
         {:ok, _} <- Client.create_branch(repo, hd(files).branch, commit, token) do
      :ok
    end
  end

  defp tree(repo, sha, token) do
    with {:ok, %{"tree" => %{"sha" => tree_sha}}} <- Client.get_commit(repo, sha, token),
         {:ok, entries} <- entries(repo, tree_sha, token) do
      {:ok, {tree_sha, entries}}
    end
  end

  defp entries(repo, tree_sha, token) do
    case Client.get_tree(repo, tree_sha, token) do
      {:ok, %{"tree" => entries, "truncated" => false}} -> {:ok, entries}
      {:error, _} = error -> error
      _ -> {:error, :repository_unavailable}
    end
  end

  defp verify_bases(entries, files) do
    Enum.reduce_while(files, :ok, fn file, :ok ->
      case verify_base(entries, file) do
        :ok -> {:cont, :ok}
        error -> {:halt, error}
      end
    end)
  end

  defp message([file]), do: "docs: update #{file.path}"
  defp message(files), do: "docs: update #{length(files)} files"

  defp verify_base(entries, file) do
    case Enum.find(entries, &(&1["path"] == file.path)) do
      nil when is_nil(file.blob_sha) ->
        :ok

      %{"type" => "blob", "sha" => sha, "mode" => mode}
      when sha == file.blob_sha and mode == file.mode ->
        :ok

      _ ->
        {:error, :base_changed}
    end
  end

  defp blob_sha(content),
    do: Base.encode16(:crypto.hash(:sha, "blob #{byte_size(content)}\0#{content}"), case: :lower)
end
