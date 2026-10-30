defmodule Glossia.EditorTest do
  use Glossia.DataCase, async: true
  use Mimic

  alias Glossia.{Editor, Projects, TestHelpers}
  alias Glossia.Editor.File, as: EditorFile
  alias Glossia.Github.{App, Client}
  alias Glossia.Translations.Repository

  setup do
    user =
      TestHelpers.create_user("editor-#{System.unique_integer([:positive])}@test.com", "editor")

    installation =
      Repo.insert!(%Glossia.Accounts.GithubInstallation{
        account_id: user.account.id,
        github_installation_id: System.unique_integer([:positive]),
        github_account_login: "example",
        github_account_type: "User",
        github_account_id: 42
      })

    {:ok, project} = Projects.create_project(user.account, %{handle: "website", name: "Website"})

    project =
      project
      |> change(%{
        github_installation_id: installation.id,
        github_repo_full_name: "example/website",
        github_repo_default_branch: "main"
      })
      |> Repo.update!()
      |> Repo.preload(:account)

    file =
      Repo.insert!(%EditorFile{
        project_id: project.id,
        path: "es/home.json",
        source_path: "en/home.json",
        locale: "es",
        format: "json",
        content: ~s({"title":"Hola","count":7}),
        blob_sha: "original-blob"
      })

    stub(App, :installation_token, fn _ -> {:ok, "test-token"} end)
    %{user: user, project: project, record: file}
  end

  test "shared drafts persist, preserve types, and reject stale saves and other projects", c do
    {:ok, [field]} = Glossia.Editor.Content.fields("json", c.record.content)

    assert {:ok, saved} =
             Editor.save(c.user, c.project, c.record.id, 1, %{field.id => "Bienvenidos"})

    assert Jason.decode!(saved.draft_content) == %{"title" => "Bienvenidos", "count" => 7}
    assert {:ok, reloaded} = Editor.get_file(c.user, c.project, c.record.id)
    assert reloaded.draft_content == saved.draft_content
    assert reloaded.content == c.record.content

    assert {:error, :stale} =
             Editor.save(c.user, c.project, c.record.id, 1, %{field.id => "Lost update"})

    {:ok, other} = Projects.create_project(c.user.account, %{handle: "other", name: "Other"})

    assert {:error, :not_found} =
             Editor.save(c.user, %{other | account: c.user.account}, c.record.id, 2, %{})

    assert {:error, :not_found} = Editor.get_file(c.user, c.project, "not-an-id")
    assert {:error, _} = Editor.list_files(nil, c.project)
    assert {:error, _} = Editor.save(nil, c.project, c.record.id, 2, %{field.id => "Anonymous"})
    assert {:ok, discarded} = Editor.discard(c.user, c.project, c.record.id, saved.lock_version)
    assert is_nil(discarded.draft_content)
  end

  @tag :tmp_dir
  test "sync plans real source/target files and never replaces a dirty base", c do
    root = c.tmp_dir
    File.mkdir_p!(Path.join(root, "en"))
    File.mkdir_p!(Path.join(root, "es"))

    File.write!(
      Path.join(root, "L10N.md"),
      "---\nsource_language: en\ntargets:\n  es: Spanish\nsources:\n  'en/*.json': 'es/*.json'\n---\n"
    )

    File.write!(Path.join(root, "en/home.json"), ~s({"title":"Welcome","count":7}))
    File.write!(Path.join(root, "es/home.json"), c.record.content)
    git(root, ["init", "-q"])
    commit(root)
    stub(Repository, :with_checkout, fn _, callback -> callback.(root) end)
    assert {:ok, files} = Editor.synchronize(c.user, c.project)

    assert Enum.sort(Enum.map(files, &{&1.path, &1.locale})) == [
             {"en/home.json", "en"},
             {"es/home.json", "es"}
           ]

    {:ok, file} = Editor.get_file(c.user, c.project, c.record.id)
    {:ok, [field]} = Glossia.Editor.Content.fields(file.format, file.content)

    {:ok, saved} =
      Editor.save(c.user, c.project, file.id, file.lock_version, %{field.id => "My draft"})

    File.write!(Path.join(root, "es/home.json"), ~s({"title":"Remote edit","count":8}))
    commit(root)
    assert {:ok, _} = Editor.synchronize(c.user, c.project)
    {:ok, conflict} = Editor.get_file(c.user, c.project, file.id)
    assert conflict.conflict
    assert conflict.draft_content == saved.draft_content
    assert conflict.content == file.content

    assert {:error, :repository_changed} =
             Editor.save(c.user, c.project, file.id, conflict.lock_version, %{})

    {:ok, _} = Editor.discard(c.user, c.project, file.id, conflict.lock_version)
    {:ok, _} = Editor.synchronize(c.user, c.project)
    {:ok, latest} = Editor.get_file(c.user, c.project, file.id)
    assert Jason.decode!(latest.content)["title"] == "Remote edit"
    refute latest.conflict
  end

  @tag :tmp_dir
  test "missing translations start from source and symlinks cannot be edited", c do
    root = c.tmp_dir
    File.mkdir_p!(Path.join(root, "en"))

    File.write!(
      Path.join(root, "L10N.md"),
      "---\nsource_language: en\ntargets:\n  fr: French\nsources:\n  'en/*.json': 'fr/*.json'\n---\n"
    )

    File.write!(Path.join(root, "en/home.json"), ~s({"title":"Welcome","enabled":true}))
    git(root, ["init", "-q"])
    commit(root)
    stub(Repository, :with_checkout, fn _, callback -> callback.(root) end)
    assert {:ok, files} = Editor.synchronize(c.user, c.project)
    target = Enum.find(files, &(&1.path == "fr/home.json"))
    assert is_nil(target.blob_sha)
    assert target.content == ~s({"title":"Welcome","enabled":true})
    {:ok, [field]} = Glossia.Editor.Content.fields(target.format, target.content)

    assert {:ok, saved} =
             Editor.save(c.user, c.project, target.id, target.lock_version, %{
               field.id => "Bonjour"
             })

    assert Jason.decode!(saved.draft_content) == %{"title" => "Bonjour", "enabled" => true}
    File.rm!(Path.join(root, "en/home.json"))
    File.ln_s!("../L10N.md", Path.join(root, "en/home.json"))
    commit(root)
    assert {:error, :unsupported_file} = Editor.synchronize(c.user, c.project)
    assert {:ok, kept} = Editor.get_file(c.user, c.project, target.id)
    assert kept.draft_content == saved.draft_content
  end

  test "publishing proposes only the selected saved file, not a default-branch write", c do
    {:ok, [field]} = Glossia.Editor.Content.fields(c.record.format, c.record.content)
    {:ok, saved} = Editor.save(c.user, c.project, c.record.id, 1, %{field.id => "Published edit"})
    stub(Client, :list_pull_requests, fn _, _, _ -> {:ok, []} end)
    stub_base(c, "original-blob")
    parent = self()

    expect(Client, :create_tree, fn "example/website", params, "test-token" ->
      assert params.base_tree == "base-tree"

      assert [%{path: "es/home.json", mode: "100644", type: "blob", content: content}] =
               params.tree

      assert Jason.decode!(content) == %{"title" => "Published edit", "count" => 7}
      send(parent, {:published_content, content})
      {:ok, %{"sha" => "new-tree"}}
    end)

    expect(Client, :create_commit, fn _, params, _ ->
      assert params.parents == ["base-commit"]
      assert params.tree == "new-tree"
      {:ok, %{"sha" => "editor-commit"}}
    end)

    expect(Client, :create_branch, fn _, branch, "editor-commit", _ ->
      assert String.starts_with?(branch, "glossia/editor-")
      {:ok, %{}}
    end)

    expect(Client, :create_pull_request, fn _, params, _ ->
      assert params.base == "main"
      assert String.starts_with?(params.head, "glossia/editor-")
      {:ok, %{"html_url" => "https://github.com/example/website/pull/12", "number" => 12}}
    end)

    assert {:ok, published} = Editor.publish(c.user, c.project, saved.id, saved.lock_version)
    assert published.pull_request_number == 12
    assert_receive {:published_content, content}
    assert published.draft_content == content
    assert published.content == c.record.content

    assert {:error, :publication_pending} =
             Editor.save(c.user, c.project, saved.id, published.lock_version, %{})
  end

  test "a changed remote file refuses publication and keeps a discardable draft", c do
    saved = c.record |> change(draft_content: ~s({"title":"Draft","count":7})) |> Repo.update!()
    stub(Client, :list_pull_requests, fn _, _, _ -> {:ok, []} end)
    stub_base(c, "somebody-elses-blob")
    reject(Client, :create_tree, 3)
    reject(Client, :create_branch, 4)
    assert {:error, :repository_changed} = Editor.publish(c.user, c.project, saved.id, 1)
    {:ok, conflict} = Editor.get_file(c.user, c.project, saved.id)
    assert conflict.conflict
    assert conflict.draft_content == saved.draft_content
    assert is_nil(conflict.branch)
    assert {:ok, _} = Editor.discard(c.user, c.project, saved.id, conflict.lock_version)
  end

  test "an uncertain publication freezes the draft and retry recovers the existing PR", c do
    saved = c.record |> change(draft_content: ~s({"title":"Draft","count":7})) |> Repo.update!()
    stub_base(c, "original-blob")
    stub(Client, :list_pull_requests, fn _, _, _ -> {:error, :timeout} end)
    assert {:error, :timeout} = Editor.publish(c.user, c.project, saved.id, 1)
    {:ok, frozen} = Editor.get_file(c.user, c.project, saved.id)
    assert frozen.branch

    assert {:error, :publication_pending} =
             Editor.discard(c.user, c.project, saved.id, frozen.lock_version)

    stub(Client, :list_pull_requests, fn _, _, opts ->
      assert opts[:head] == "example:#{frozen.branch}"
      {:ok, [%{"html_url" => "https://github.com/example/website/pull/13", "number" => 13}]}
    end)

    stub_frozen_branch([frozen])
    reject(Client, :create_branch, 4)
    reject(Client, :create_pull_request, 3)
    assert {:ok, recovered} = Editor.publish(c.user, c.project, saved.id, frozen.lock_version)
    assert recovered.pull_request_number == 13
  end

  test "one publication contains precisely the selected asymmetric JSON and Markdown drafts", c do
    files = saved_pair(c)
    stub_base(c, "original-blob")
    stub(Client, :list_pull_requests, fn _, _, _ -> {:ok, []} end)
    unselected = insert_markdown(c, "es/unselected.md")

    expect(Client, :create_tree, fn _, params, _ ->
      assert params.base_tree == "base-tree"
      assert Enum.map(params.tree, & &1.path) == Enum.sort(Enum.map(files, & &1.path))
      json = Enum.find(params.tree, &(&1.path == "es/home.json"))
      markdown = Enum.find(params.tree, &(&1.path == "es/guide.md"))
      assert Jason.decode!(json.content) == %{"title" => "Grouped JSON", "count" => 7}

      assert markdown.content ==
               "---\ntitle: Guide\nweight: 3\n---\n\n# Edited guide\n\nA longer Markdown body.\n"

      assert markdown.mode == "100755"
      {:ok, %{"sha" => "group-tree"}}
    end)

    expect(Client, :create_commit, fn _, params, _ ->
      assert params.parents == ["base-commit"]
      assert params.tree == "group-tree"
      {:ok, %{"sha" => "group-commit"}}
    end)

    expect(Client, :create_branch, fn _, _, "group-commit", _ -> {:ok, %{}} end)

    expect(Client, :create_pull_request, fn _, params, _ ->
      assert params.base == "main"
      assert params.body =~ "es/home.json"
      assert params.body =~ "es/guide.md"
      refute params.body =~ unselected.path
      {:ok, %{"html_url" => "https://github.com/example/website/pull/20", "number" => 20}}
    end)

    assert {:ok, published} = Editor.publish_many(c.user, c.project, versions(files))
    assert length(Enum.uniq(Enum.map(published, & &1.branch))) == 1
    assert Enum.all?(published, &(&1.pull_request_number == 20))
    assert Repo.get!(EditorFile, unselected.id).branch == nil
  end

  test "group stale versions and local conflicts fail atomically before remote IO", c do
    [json, markdown] = files = saved_pair(c)
    reject(Client, :get_ref, 3)
    reject(Client, :create_tree, 3)
    reject(Client, :create_commit, 3)
    reject(Client, :create_branch, 4)
    reject(Client, :create_pull_request, 3)

    assert {:error, :stale} =
             Editor.publish_many(c.user, c.project, Map.put(versions(files), markdown.id, 1))

    markdown |> change(conflict: true) |> Repo.update!()
    assert {:error, :repository_changed} = Editor.publish_many(c.user, c.project, versions(files))
    assert Repo.get!(EditorFile, json.id).lock_version == json.lock_version
    assert Enum.all?(files, &is_nil(Repo.get!(EditorFile, &1.id).branch))
  end

  test "every remote base is checked before any group write and conflicts retain drafts", c do
    files = saved_pair(c)
    # The first (Markdown) base matches its absent target; the later JSON
    # conflict must prevent writes for BOTH files.
    stub_base(c, "changed-json")

    reject(Client, :create_tree, 3)
    reject(Client, :create_commit, 3)
    reject(Client, :create_branch, 4)
    reject(Client, :create_pull_request, 3)
    assert {:error, :repository_changed} = Editor.publish_many(c.user, c.project, versions(files))

    Enum.each(files, fn file ->
      current = Repo.get!(EditorFile, file.id)
      assert is_nil(current.branch)
      assert current.conflict
      assert current.draft_content == file.draft_content
      assert {:ok, _} = Editor.discard(c.user, c.project, file.id, current.lock_version)
    end)
  end

  test "uncertain group creation retries the full manifest through a single-file entry", c do
    files = saved_pair(c)
    stub_base(c, "original-blob")
    stub(Client, :list_pull_requests, fn _, _, _ -> {:ok, []} end)

    expect(Client, :create_tree, fn _, %{tree: tree}, _ ->
      assert length(tree) == 2
      {:ok, %{"sha" => "group-tree"}}
    end)

    expect(Client, :create_commit, fn _, _, _ -> {:ok, %{"sha" => "group-commit"}} end)
    expect(Client, :create_branch, fn _, _, _, _ -> {:error, :timeout} end)
    assert {:error, :timeout} = Editor.publish_many(c.user, c.project, versions(files))
    frozen = Enum.map(files, &Repo.get!(EditorFile, &1.id))
    [first, second] = frozen
    assert first.branch == second.branch

    assert {:error, :publication_pending} =
             Editor.publish_many(c.user, c.project, versions([first]))

    extra = insert_markdown(c, "es/extra.md")

    assert {:error, :publication_pending} =
             Editor.publish_many(c.user, c.project, versions(frozen ++ [extra]))

    extra |> change(branch: "glossia/editor-another") |> Repo.update!()

    assert {:error, :publication_pending} =
             Editor.publish_many(c.user, c.project, versions(frozen ++ [extra]))

    # A branch created before the lost response already contains BOTH drafts.
    stub_frozen_branch(frozen)
    reject(Client, :create_tree, 3)
    reject(Client, :create_commit, 3)
    reject(Client, :create_branch, 4)

    expect(Client, :create_pull_request, fn _, params, _ ->
      assert params.head == first.branch
      assert params.body =~ first.path
      assert params.body =~ second.path
      {:ok, %{"html_url" => "https://github.com/example/website/pull/21", "number" => 21}}
    end)

    assert {:ok, recovered} = Editor.publish(c.user, c.project, first.id, first.lock_version)
    assert recovered.id == first.id
    assert Repo.get!(EditorFile, second.id).pull_request_number == 21
    assert Repo.get!(EditorFile, second.id).draft_content == second.draft_content
  end

  test "retry never adopts partial or injected branch content even when a PR exists", c do
    files = saved_pair(c)
    stub_base(c, "original-blob")
    stub(Client, :list_pull_requests, fn _, _, _ -> {:error, :timeout} end)
    assert {:error, :timeout} = Editor.publish_many(c.user, c.project, versions(files))
    frozen = Enum.map(files, &Repo.get!(EditorFile, &1.id))
    stub(Client, :list_pull_requests, fn _, _, _ -> {:ok, [%{"number" => 22}]} end)
    stub_frozen_branch(frozen)
    reject(Client, :create_tree, 3)
    reject(Client, :create_pull_request, 3)

    for entries <- [
          Enum.take(draft_entries(frozen), 1),
          draft_entries(frozen) ++
            [%{"path" => "injected.txt", "type" => "blob", "mode" => "100644", "sha" => "evil"}]
        ] do
      stub(Client, :get_tree, fn _, tree, _ ->
        {:ok,
         %{
           "truncated" => false,
           "tree" => if(tree == "base-tree", do: base_entries(), else: entries)
         }}
      end)

      assert {:error, :repository_changed} =
               Editor.publish_many(c.user, c.project, versions(frozen))

      assert Enum.all?(frozen, &(Repo.get!(EditorFile, &1.id).branch == &1.branch))
      assert Enum.all?(frozen, &is_nil(Repo.get!(EditorFile, &1.id).pull_request_number))
    end

    stub_frozen_branch(frozen)
    assert {:ok, recovered} = Editor.publish_many(c.user, c.project, versions(frozen))
    assert Enum.all?(recovered, &(&1.pull_request_number == 22))
  end

  test "retry with a moved base never unfreezes an uncertain group", c do
    files = saved_pair(c)
    stub_base(c, "original-blob")
    stub(Client, :list_pull_requests, fn _, _, _ -> {:error, :timeout} end)
    assert {:error, :timeout} = Editor.publish_many(c.user, c.project, versions(files))
    frozen = Enum.map(files, &Repo.get!(EditorFile, &1.id))
    stub_base(c, "moved")
    stub(Client, :list_pull_requests, fn _, _, _ -> {:ok, []} end)
    reject(Client, :create_tree, 3)

    assert {:error, :repository_changed} =
             Editor.publish_many(c.user, c.project, versions(frozen))

    assert Enum.all?(frozen, &(Repo.get!(EditorFile, &1.id).branch == &1.branch))
  end

  test "group selection validates input, authorization, no-op drafts and project isolation", c do
    files = saved_pair(c)
    reject(Client, :get_ref, 3)
    assert {:error, :invalid_selection} = Editor.publish_many(c.user, c.project, %{})
    assert {:error, :invalid_selection} = Editor.publish_many(c.user, c.project, %{"bad" => 1})

    assert {:error, :invalid_selection} =
             Editor.publish_many(c.user, c.project, %{c.record.id => "2"})

    assert {:error, _} = Editor.publish_many(nil, c.project, versions(files))

    {:ok, other} =
      Projects.create_project(c.user.account, %{handle: "isolated", name: "Isolated"})

    foreign = insert_markdown(%{c | project: other}, "es/foreign.md")

    assert {:error, :not_found} =
             Editor.publish_many(c.user, c.project, versions(files ++ [foreign]))

    assert {:error, :not_found} =
             Editor.publish_many(
               c.user,
               c.project,
               versions(files) |> Map.put(Ecto.UUID.generate(), 1)
             )

    clean = insert_markdown(c, "es/clean.md") |> change(draft_content: nil) |> Repo.update!()

    assert {:error, :no_changes} =
             Editor.publish_many(c.user, c.project, versions(files ++ [clean]))

    assert Enum.all?(files, &is_nil(Repo.get!(EditorFile, &1.id).branch))
  end

  test "review keeps open drafts frozen, retains closed edits, and clears merged edits", c do
    attrs = %{
      draft_content: ~s({"title":"Reviewed edit","count":7}),
      branch: "glossia/editor-review",
      pull_request_number: 14,
      pull_request_url: "https://github.com/example/website/pull/14"
    }

    c.record |> change(attrs) |> Repo.update!()
    sibling = insert_markdown(c, "es/review.md")
    sibling = sibling |> change(Map.drop(attrs, [:draft_content])) |> Repo.update!()

    {:ok, other} =
      Projects.create_project(c.user.account, %{handle: "other-review", name: "Other"})

    foreign = insert_markdown(%{c | project: other}, "es/foreign.md")
    foreign = foreign |> change(Map.drop(attrs, [:draft_content])) |> Repo.update!()
    stub(Client, :get_pull_request, fn _, 14, _ -> {:ok, %{"state" => "open"}} end)
    assert {:error, :review_open} = Editor.refresh_review(c.user, c.project, c.record.id)
    {:ok, frozen} = Editor.get_file(c.user, c.project, c.record.id)
    assert frozen.branch == attrs.branch
    assert Repo.get!(EditorFile, sibling.id).branch == attrs.branch

    stub(Client, :get_pull_request, fn _, 14, _ ->
      {:ok, %{"state" => "closed", "merged_at" => nil}}
    end)

    assert {:ok, closed} = Editor.refresh_review(c.user, c.project, c.record.id)
    assert is_nil(closed.branch)
    assert closed.draft_content == attrs.draft_content
    closed_sibling = Repo.get!(EditorFile, sibling.id)
    assert is_nil(closed_sibling.branch)
    assert is_nil(closed_sibling.pull_request_number)
    assert closed_sibling.draft_content == sibling.draft_content
    closed |> change(attrs) |> Repo.update!()
    closed_sibling |> change(Map.drop(attrs, [:draft_content])) |> Repo.update!()

    stub(Client, :get_pull_request, fn _, 14, _ ->
      {:ok, %{"state" => "closed", "merged_at" => "2026-10-30T12:00:00Z"}}
    end)

    assert {:ok, merged} = Editor.refresh_review(c.user, c.project, sibling.id)
    assert merged.id == sibling.id

    for id <- [c.record.id, sibling.id] do
      merged = Repo.get!(EditorFile, id)
      assert is_nil(merged.branch)
      assert is_nil(merged.draft_content)
      assert is_nil(merged.pull_request_url)
      assert is_nil(merged.pull_request_number)
    end

    assert Repo.get!(EditorFile, foreign.id).branch == foreign.branch
    assert Repo.get!(EditorFile, foreign.id).draft_content == foreign.draft_content
  end

  defp saved_pair(c) do
    {:ok, [field]} = Glossia.Editor.Content.fields(c.record.format, c.record.content)
    {:ok, json} = Editor.save(c.user, c.project, c.record.id, 1, %{field.id => "Grouped JSON"})
    markdown = insert_markdown(c, "es/guide.md")

    {:ok, markdown} =
      Editor.save(c.user, c.project, markdown.id, 1, %{
        "body" => "\n# Edited guide\n\nA longer Markdown body.\n"
      })

    [json, markdown]
  end

  defp insert_markdown(c, path) do
    Repo.insert!(%EditorFile{
      project_id: c.project.id,
      path: path,
      source_path: "en/guide.md",
      locale: "es",
      format: "markdown",
      mode: "100755",
      content: "---\ntitle: Guide\nweight: 3\n---\n\n# Original\n",
      draft_content: "---\ntitle: Guide\nweight: 3\n---\n\n# Original draft\n"
    })
  end

  defp versions(files), do: Map.new(files, &{&1.id, &1.lock_version})

  defp base_entries do
    [%{"path" => "es/home.json", "type" => "blob", "mode" => "100644", "sha" => "original-blob"}]
  end

  defp draft_entries(files) do
    Enum.map(files, fn file ->
      sha =
        Base.encode16(
          :crypto.hash(:sha, "blob #{byte_size(file.draft_content)}\0#{file.draft_content}"),
          case: :lower
        )

      %{"path" => file.path, "type" => "blob", "mode" => file.mode, "sha" => sha}
    end)
  end

  defp stub_frozen_branch(files) do
    stub(Client, :get_ref, fn _, _, _ -> {:ok, %{"object" => %{"sha" => "frozen-commit"}}} end)

    stub(Client, :get_commit, fn _, sha, _ ->
      if sha == "frozen-commit",
        do:
          {:ok, %{"tree" => %{"sha" => "frozen-tree"}, "parents" => [%{"sha" => "base-commit"}]}},
        else: {:ok, %{"tree" => %{"sha" => "base-tree"}}}
    end)

    stub(Client, :get_tree, fn _, tree, _ ->
      {:ok,
       %{
         "truncated" => false,
         "tree" => if(tree == "base-tree", do: base_entries(), else: draft_entries(files))
       }}
    end)
  end

  defp stub_base(_c, sha) do
    stub(Client, :get_ref, fn _, ref, _ ->
      if ref == "heads/main",
        do: {:ok, %{"object" => %{"sha" => "base-commit"}}},
        else: {:error, {:api_error, 404, %{}}}
    end)

    stub(Client, :get_commit, fn _, "base-commit", _ ->
      {:ok, %{"tree" => %{"sha" => "base-tree"}}}
    end)

    stub(Client, :get_tree, fn _, "base-tree", _ ->
      {:ok,
       %{
         "truncated" => false,
         "tree" => [
           %{"path" => "es/home.json", "type" => "blob", "mode" => "100644", "sha" => sha}
         ]
       }}
    end)
  end

  defp commit(root) do
    git(root, ["add", "."])

    git(root, [
      "-c",
      "user.name=Test",
      "-c",
      "user.email=test@example.com",
      "-c",
      "commit.gpgsign=false",
      "commit",
      "-qm",
      "content"
    ])
  end

  defp git(root, args) do
    {output, 0} = MuonTrap.cmd("git", ["-C", root | args], into: "", timeout: 30_000)
    output
  end
end
