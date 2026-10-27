defmodule Glossia.Translations.Repository do
  @moduledoc """
  Disposable Git checkouts shared by assessment and publication.

  Source is merged locally, never through GitHub's branch-mutating merge API.
  Publication rebuilds from the current remote head and includes that merge
  only when the batch changes the locally synchronized tree.
  """

  @git_timeout_ms :timer.minutes(10)

  def with_checkout(repository, callback) do
    dir = Path.join(System.tmp_dir!(), "glossia-translate-#{Ecto.UUID.generate()}")
    branch = repository[:publication_branch] || repository.default_branch

    try do
      with {_output, 0} <- git(["clone", "--branch", branch, clone_source(repository), dir]),
           :ok <-
             checkout(
               dir,
               repository[:publication_commit_sha] || repository[:publication_branch] ||
                 repository[:commit_sha]
             ),
           :ok <- synchronize_source(dir, repository) do
        callback.(dir)
      else
        {:error, _} = error -> error
        {_output, code} -> {:error, {:clone_failed, code}}
      end
    after
      File.rm_rf(dir)
    end
  end

  def prepare_publication(repository, changes) do
    with_checkout(repository, fn dir ->
      with :ok <- verify_remote_advance(dir, repository, changes) do
        changes = Enum.reject(changes, &unchanged?(dir, &1))
        parent = repository[:publication_commit_sha] || repository.commit_sha

        if changes == [] do
          {:ok, %{changes: [], parents: [parent]}}
        else
          with {:ok, source_changes} <- source_changes(dir, parent),
               {merged_head, 0} <- git(["-C", dir, "rev-parse", "HEAD"]) do
            # A local merge has two parents. Publish its tree and the validated
            # batch in one commit, retaining source ancestry without a separate
            # ref update (or a force push).
            parents =
              if String.trim(merged_head) == parent,
                do: [parent],
                else: Enum.uniq([parent, repository.commit_sha])

            combined =
              (source_changes ++ changes)
              |> Enum.reverse()
              |> Enum.uniq_by(& &1.path)
              |> Enum.reverse()

            {:ok, %{changes: combined, parents: parents}}
          end
        end
      end
    end)
  end

  defp verify_remote_advance(dir, repository, changes) do
    current = repository[:publication_commit_sha] || repository.commit_sha
    expected = repository[:expected_publication_commit_sha] || current

    if current == expected do
      :ok
    else
      # Reconcile an uncertain earlier write only if every remote difference
      # is an already-present part of this batch. Never adopt a human edit or
      # changed validation input and then overwrite it with a stale result.
      with {tree, 0} <-
             git([
               "-C",
               dir,
               "merge-tree",
               "--write-tree",
               "--no-messages",
               expected,
               repository.commit_sha
             ]),
           {:ok, remote_changes} <- source_changes(dir, String.trim(tree)),
           true <-
             Enum.all?(remote_changes, fn remote ->
               Enum.any?(changes, &(&1.path == remote.path and unchanged?(dir, &1)))
             end) do
        :ok
      else
        _ -> {:error, :translation_branch_conflict}
      end
    end
  end

  defp unchanged?(dir, %{path: path, status: "deleted"}) do
    case git(["-C", dir, "cat-file", "-e", "HEAD:#{path}"]) do
      {_, 0} -> false
      _ -> true
    end
  end

  defp unchanged?(dir, %{path: path, content: content} = change) do
    # Symlink targets are blobs too. Equal bytes do not make a symlink (or an
    # executable) the regular file that was validated and would be published.
    case git(["--literal-pathspecs", "-C", dir, "ls-tree", "-z", "HEAD", "--", path]) do
      {entry, 0} ->
        case :binary.split(entry, "\t") do
          [header, _path] ->
            String.starts_with?(header, "#{Map.get(change, :mode, "100644")} blob ") and
              git(["-C", dir, "cat-file", "blob", "HEAD:#{path}"]) == {content, 0}

          _ ->
            false
        end

      _ ->
        false
    end
  end

  defp source_changes(dir, parent) do
    case git(["-C", dir, "diff-tree", "--raw", "-r", "-z", "--no-renames", parent, "HEAD"]) do
      {output, 0} ->
        output
        |> String.split(<<0>>, trim: true)
        |> Enum.chunk_every(2)
        |> Enum.reduce_while({:ok, []}, fn [header, path], {:ok, changes} ->
          [_old_mode, mode, _old_sha, sha, status] = String.split(header, " ")

          case source_entry(dir, path, mode, sha, status) do
            {:ok, change} -> {:cont, {:ok, [change | changes]}}
            error -> {:halt, error}
          end
        end)

      _ ->
        {:error, :translation_change_manifest_incomplete}
    end
  end

  defp source_entry(_dir, path, _mode, _sha, "D"),
    do: {:ok, %{path: path, status: "deleted"}}

  # Gitlinks refer to commits in another repository, not blobs to upload.
  defp source_entry(_dir, path, "160000", sha, _status),
    do: {:ok, %{path: path, mode: "160000", type: "commit", sha: sha}}

  defp source_entry(dir, path, mode, sha, _status) do
    case git(["-C", dir, "cat-file", "blob", sha]) do
      {content, 0} -> {:ok, %{path: path, mode: mode, content: content}}
      _ -> {:error, :translation_change_manifest_incomplete}
    end
  end

  defp synchronize_source(dir, %{publication_branch: branch, commit_sha: sha})
       when is_binary(branch) and branch != "" and is_binary(sha) and sha != "" do
    case git(["-C", dir, "merge", "--no-edit", "--no-ff", sha]) do
      {_, 0} -> :ok
      _ -> {:error, :translation_branch_conflict}
    end
  end

  defp synchronize_source(_dir, _repository), do: :ok

  defp checkout(_dir, sha) when sha in [nil, ""], do: :ok

  defp checkout(dir, sha) do
    case git(["-C", dir, "checkout", "--detach", sha]) do
      {_, 0} -> :ok
      _ -> {:error, :translation_source_history_changed}
    end
  end

  defp clone_source(repository) do
    local_dir = Application.get_env(:glossia, Glossia.Translations, [])[:local_remotes_dir]
    local_path = local_dir && Path.join(Path.expand(local_dir), repository.full_name)

    if local_path && File.dir?(local_path),
      do: local_path,
      else: "https://x-access-token:#{repository[:token]}@github.com/#{repository.full_name}.git"
  end

  defp git(args) do
    MuonTrap.cmd(
      "git",
      [
        "-c",
        "user.name=Glossia",
        "-c",
        "user.email=bot@glossia.ai",
        "-c",
        "commit.gpgsign=false",
        "-c",
        "core.hooksPath=/dev/null"
        | args
      ],
      into: "",
      stderr_to_stdout: true,
      timeout: @git_timeout_ms
    )
  end
end
