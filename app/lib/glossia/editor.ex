defmodule Glossia.Editor do
  @moduledoc """
  Repository-configured source and target files with shared, durable drafts.
  Repository snapshots never overwrite drafts. Writes use the version the
  editor actually displayed; publication freezes drafts before remote writes.
  """
  import Ecto.Query

  alias Glossia.{Authz, Repo}
  alias Glossia.Accounts.Project
  alias Glossia.Editor.{Content, File, Publisher}
  alias Glossia.Github.App
  alias Glossia.Translations.{Format, Planner, Repository}

  @max_file_bytes 1_000_000
  @max_files 2_000

  def authorize(user, project), do: Authz.authorize(:project_write, user, project.account)

  def list_files(user, project) do
    with :ok <- authorize(user, project) do
      {:ok, Repo.all(from f in scoped(project), order_by: [asc: f.source_path, asc: f.path])}
    end
  end

  def get_file(user, project, id) do
    with :ok <- authorize(user, project),
         {:ok, id} <- Ecto.UUID.cast(id) do
      case Repo.get(scoped(project), id) do
        nil -> {:error, :not_found}
        file -> {:ok, file}
      end
    else
      :error -> {:error, :not_found}
      error -> error
    end
  end

  def save(user, project, id, version, values) when is_map(values) do
    with :ok <- authorize(user, project) do
      locked(project, id, fn file ->
        editable!(file, version)

        case Content.update(file.format, file.draft_content || file.content, values) do
          {:ok, content} when byte_size(content) <= @max_file_bytes ->
            update!(file, %{draft_content: if(content != file.content, do: content)})

          {:ok, _} ->
            Repo.rollback(:file_too_large)

          {:error, reason} ->
            Repo.rollback(reason)
        end
      end)
    end
  end

  def discard(user, project, id, version) do
    with :ok <- authorize(user, project) do
      locked(project, id, fn file ->
        if file.lock_version != version, do: Repo.rollback(:stale)
        if file.branch, do: Repo.rollback(:publication_pending)
        update!(file, %{draft_content: nil})
      end)
    end
  end

  def synchronize(user, project) do
    with :ok <- authorize(user, project),
         {:ok, repository} <- repository(project),
         {:ok, entries} <- Repository.with_checkout(repository, &inventory/1) do
      Repo.transaction(fn ->
        lock_project(project)
        existing = Repo.all(scoped(project))
        paths = MapSet.new(entries, & &1.path)

        Enum.each(existing, fn file ->
          if not MapSet.member?(paths, file.path),
            do: update!(file, %{active: false, conflict: not is_nil(file.draft_content)})
        end)

        Enum.map(entries, fn attrs ->
          case Enum.find(existing, &(&1.path == attrs.path)) do
            nil ->
              %File{project_id: project.id}
              |> Ecto.Changeset.change(attrs)
              |> Repo.insert!()

            file ->
              # Keep the precise original base while a person is editing or a
              # publication might have reached GitHub. Discard + sync rebases.
              if file.draft_content || file.branch do
                update!(file, %{
                  active: true,
                  conflict:
                    Enum.any?([:blob_sha, :mode, :source_path, :locale, :format], fn key ->
                      Map.fetch!(file, key) != Map.fetch!(attrs, key)
                    end)
                })
              else
                update!(file, Map.merge(attrs, %{active: true, conflict: false}))
              end
          end
        end)
      end)
    end
  end

  def publish(user, project, id, version) do
    case publish_selection(user, project, %{id => version}, :expand) do
      {:ok, files} -> {:ok, Enum.find(files, &(&1.id == Ecto.UUID.cast!(id)))}
      error -> error
    end
  end

  @doc """
  Publishes a nonempty map of file UUID strings to saved integer lock versions.
  Returns `{:ok, files}` ordered by path. A retry must select the entire frozen
  branch group with current versions; subsets or mixed groups return
  `{:error, :publication_pending}`. `publish/4` expands a member to its group.

  Invalid maps return `:invalid_selection`, missing/project-external files
  `:not_found`, outdated versions `:stale`, clean files `:no_changes`, and local
  or remote base conflicts `:repository_changed`. Pre-reservation conflicts
  remain discardable. All failures after reservation retain the frozen group.
  Authorization, repository connection, and GitHub errors propagate unchanged.
  """
  def publish_many(user, project, versions) do
    publish_selection(user, project, versions, :exact)
  end

  defp publish_selection(user, project, versions, selection) do
    with :ok <- authorize(user, project),
         {:ok, versions} <- publication_versions(versions),
         {:ok, repository} <- repository(project),
         {:ok, {:ok, files}} <-
           project_transaction(project, fn ->
             files =
               Repo.all(
                 from f in scoped(project), where: f.id in ^Map.keys(versions), order_by: f.path
               )

             if length(files) != map_size(versions), do: Repo.rollback(:not_found)

             Enum.each(files, fn file ->
               if file.lock_version != versions[file.id], do: Repo.rollback(:stale)
             end)

             case Enum.uniq(Enum.map(files, & &1.branch)) do
               [nil] ->
                 Enum.each(files, fn file ->
                   editable!(file, versions[file.id])
                   if is_nil(file.draft_content), do: Repo.rollback(:no_changes)
                 end)

                 # Fail discardably before reservation. Once a branch is
                 # reserved, even an uncertain attempt must never unfreeze it.
                 case Publisher.check_bases(repository, files) do
                   :ok ->
                     branch = "glossia/editor-#{Ecto.UUID.generate()}"
                     {:ok, Enum.map(files, &update!(&1, %{branch: branch}))}

                   {:error, :base_changed} ->
                     Enum.each(files, &update!(&1, %{conflict: true}))
                     {:error, :repository_changed}

                   {:error, reason} ->
                     Repo.rollback(reason)
                 end

               [branch] when is_binary(branch) ->
                 group = publication_group(project, branch)

                 if selection == :exact && length(group) != length(files),
                   do: Repo.rollback(:publication_pending)

                 {:ok, group}

               _ ->
                 Repo.rollback(:publication_pending)
             end
           end) do
      # Serialize retries as well as edits. The reservation above survives a
      # crash here, so a lost GitHub response is recovered on the same branch.
      case project_transaction(project, fn ->
             current = publication_group(project, hd(files).branch)
             if Enum.map(current, & &1.id) != Enum.map(files, & &1.id), do: Repo.rollback(:stale)

             case Publisher.publish(repository, current) do
               {:ok, pr} ->
                 {:ok,
                  Enum.map(
                    current,
                    &update!(&1, %{
                      pull_request_url: pr["html_url"],
                      pull_request_number: pr["number"]
                    })
                  )}

               {:error, :base_changed} ->
                 # The base moved after reservation. Retain the manifest: a
                 # previous attempt could already have made a remote write.
                 {:error, :repository_changed}

               {:error, _} = error ->
                 error
             end
           end) do
        {:ok, result} -> result
        error -> error
      end
    else
      {:ok, {:error, _} = error} -> error
      error -> error
    end
  end

  defp publication_versions(versions) when is_map(versions) and map_size(versions) > 0 do
    Enum.reduce_while(versions, {:ok, %{}}, fn {id, version}, {:ok, acc} ->
      case Ecto.UUID.cast(id) do
        {:ok, uuid} when is_binary(id) and is_integer(version) ->
          if Map.has_key?(acc, uuid),
            do: {:halt, {:error, :invalid_selection}},
            else: {:cont, {:ok, Map.put(acc, uuid, version)}}

        _ ->
          {:halt, {:error, :invalid_selection}}
      end
    end)
  end

  defp publication_versions(_), do: {:error, :invalid_selection}

  defp publication_group(project, branch) do
    Repo.all(from f in scoped(project), where: f.branch == ^branch, order_by: f.path)
  end

  # Explicitly reconcile a submitted change after review. Closed, unmerged PRs
  # retain the draft; merged PRs are reloaded from the repository by sync.
  def refresh_review(user, project, id) do
    with :ok <- authorize(user, project),
         {:ok, file} <- get_file(user, project, id),
         true <- not is_nil(file.pull_request_number) && not is_nil(file.branch),
         {:ok, repository} <- repository(project),
         {:ok, %{"state" => "closed"} = pr} <-
           Glossia.Github.Client.get_pull_request(
             repository.full_name,
             file.pull_request_number,
             repository.token
           ) do
      locked(project, id, fn current ->
        if current.branch != file.branch, do: Repo.rollback(:stale)

        if current.pull_request_number != file.pull_request_number, do: Repo.rollback(:stale)

        publication_group(project, file.branch)
        |> Enum.map(fn member ->
          update!(member, %{
            branch: nil,
            pull_request_url: nil,
            pull_request_number: nil,
            draft_content: if(pr["merged_at"], do: nil, else: member.draft_content)
          })
        end)
        |> Enum.find(&(&1.id == file.id))
      end)
    else
      {:ok, %{"state" => "open"}} -> {:error, :review_open}
      false -> {:error, :not_found}
      error -> error
    end
  end

  def repository(project) do
    project = Repo.preload(project, :github_installation)

    if project.github_installation && project.github_repo_full_name do
      with {:ok, token} <-
             App.installation_token(project.github_installation.github_installation_id) do
        {:ok,
         %{
           full_name: project.github_repo_full_name,
           default_branch: project.github_repo_default_branch || "main",
           token: token
         }}
      end
    else
      {:error, :repository_not_connected}
    end
  end

  defp inventory(root) do
    with {:ok, items} <- Planner.build_plan(root),
         {tree, 0} <- git(root, ["ls-tree", "-r", "-z", "HEAD"]) do
      blobs =
        tree
        |> String.split(<<0>>, trim: true)
        |> Map.new(fn entry ->
          [header, path] = :binary.split(entry, "\t")
          [mode, type, sha] = String.split(header)
          {path, %{mode: mode, type: type, sha: sha}}
        end)

      entries =
        items
        |> Enum.flat_map(fn item ->
          [
            %{
              path: item.source_path,
              source_path: item.source_path,
              locale: item.source_language || "source",
              format: Format.detect(item.source_path)
            },
            %{
              path: item.output_path,
              source_path: item.source_path,
              locale: item.locale,
              format: item.format
            }
          ]
        end)
        |> Enum.filter(fn entry ->
          entry.format in ~w(markdown json yaml) ||
            String.downcase(Path.extname(entry.path)) in ~w(.txt .text)
        end)
        |> Enum.uniq_by(& &1.path)

      if length(entries) > @max_files do
        {:error, :too_many_files}
      else
        Enum.reduce_while(entries, {:ok, []}, fn attrs, {:ok, acc} ->
          case read_entry(root, blobs, attrs) do
            {:ok, entry} -> {:cont, {:ok, [entry | acc]}}
            error -> {:halt, error}
          end
        end)
      end
    else
      {:error, _} = error -> error
      _ -> {:error, :repository_unavailable}
    end
  end

  defp read_entry(root, blobs, attrs) do
    blob = blobs[attrs.path]
    template = blob || blobs[attrs.source_path]

    with %{type: "blob", mode: mode, sha: sha} when mode in ["100644", "100755"] <- template,
         {size, 0} <- git(root, ["cat-file", "-s", sha]),
         true <- String.to_integer(String.trim(size)) <= @max_file_bytes,
         {content, 0} <- git(root, ["cat-file", "blob", sha]),
         true <- String.valid?(content) && not String.contains?(content, <<0>>) do
      {:ok, Map.merge(attrs, %{content: content, blob_sha: blob && blob.sha, mode: mode})}
    else
      _ -> {:error, :unsupported_file}
    end
  end

  defp git(root, args),
    do: MuonTrap.cmd("git", ["-C", root | args], into: "", timeout: 30_000)

  defp scoped(project), do: from(f in File, where: f.project_id == ^project.id)

  defp lock_project(project),
    do: Repo.one!(from p in Project, where: p.id == ^project.id, lock: "FOR UPDATE")

  defp project_transaction(project, fun) do
    Repo.transaction(
      fn ->
        lock_project(project)
        fun.()
      end,
      timeout: 120_000
    )
  end

  defp locked(project, id, fun) do
    with {:ok, id} <- Ecto.UUID.cast(id) do
      Repo.transaction(
        fn ->
          lock_project(project)
          file = Repo.get(scoped(project), id) || Repo.rollback(:not_found)
          fun.(file)
        end,
        timeout: 120_000
      )
    else
      :error -> {:error, :not_found}
    end
  end

  defp editable!(file, version) do
    if file.lock_version != version, do: Repo.rollback(:stale)
    if file.branch, do: Repo.rollback(:publication_pending)
    if not file.active || file.conflict, do: Repo.rollback(:repository_changed)
  end

  defp update!(file, attrs) do
    file
    |> Ecto.Changeset.change(attrs)
    |> Ecto.Changeset.optimistic_lock(:lock_version)
    |> Repo.update!()
  end
end
