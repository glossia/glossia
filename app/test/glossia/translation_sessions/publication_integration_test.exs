defmodule Glossia.TranslationSessions.PublicationIntegrationTest do
  use Glossia.DataCase, async: false
  use Mimic

  alias Glossia.Github.Client
  alias Glossia.Github.Installations
  alias Glossia.Projects
  alias Glossia.TranslationSessions
  alias Glossia.TranslationSessions.Translate
  alias Glossia.TranslationStubs

  @branch "glossia/translate-rolling"

  @moduletag :tmp_dir

  setup %{tmp_dir: root} do
    remote = Path.join(root, "glossia/demo")
    File.mkdir_p!(remote)
    git(remote, ["init", "-b", "main"])

    File.write!(Path.join(remote, "L10N.md"), """
    ---
    source_language: en
    model: openai/gpt-5
    sources:
      "guide.md": "{locale}/guide.md"
    targets:
      es: Spanish
    ---
    """)

    File.write!(Path.join(remote, "guide.md"), "# Hello\n")
    File.write!(Path.join(remote, "obsolete.txt"), "Remove me\n")
    git(remote, ["add", "."])
    git(remote, ["commit", "-m", "initial source"])
    source = sha(remote, "HEAD")
    git(remote, ["branch", @branch])

    original = Application.get_env(:glossia, Glossia.Translations, [])
    Application.put_env(:glossia, Glossia.Translations, local_remotes_dir: root)
    on_exit(fn -> Application.put_env(:glossia, Glossia.Translations, original) end)

    user = Glossia.TestHelpers.create_user("publication-integration@test.com", "publication-git")

    {:ok, installation} =
      Installations.create_installation(user.account, %{
        github_installation_id: 42,
        github_account_login: "glossia",
        github_account_type: "Organization",
        github_account_id: 4242
      })

    {:ok, project} =
      Projects.create_project_from_github(user.account, installation.id, %{
        handle: "publication-git",
        name: "Publication",
        github_repo_full_name: "glossia/demo",
        github_repo_default_branch: "main"
      })

    writes = start_supervised!({Agent, fn -> %{count: 0, lose_response: false} end})
    github(remote, writes)

    stub(Glossia.Translations, :translate_stream, fn _, payload, _, _ ->
      text = TranslationStubs.respond(payload, &String.replace(&1, "Hello", "Hola"))
      {:ok, %{text: text, model: "openai/gpt-5", provider: "openai"}}
    end)

    {:ok, initial} =
      TranslationSessions.create_session(user.account, project, %{
        commit_sha: source,
        source_language: "en",
        target_languages: ["es"],
        publication_branch: @branch,
        publication_commit_sha: source,
        pull_request_number: 2,
        pull_request_url: "https://github.com/glossia/demo/pull/2"
      })

    assert :ok = Translate.run(initial.id)
    assert count(writes) == 1
    Agent.update(writes, &%{&1 | count: 0})

    %{remote: remote, user: user, project: project, initial: initial, writes: writes}
  end

  test "unrelated source pushes assess existing outputs without advancing the remote", ctx do
    before = sha(ctx.remote, @branch)
    pushed_at = Repo.get!(Glossia.Accounts.Project, ctx.project.id).translation_last_pushed_at
    File.write!(Path.join(ctx.remote, "README.md"), "An unrelated change\n")
    source = commit_source(ctx.remote)
    session = continuation(ctx, source)
    reject(&Glossia.Translations.translate_stream/4)

    assert :ok = Translate.run(session.id)
    assert sha(ctx.remote, @branch) == before
    assert count(ctx.writes) == 0

    assert Repo.get!(Glossia.Accounts.Project, ctx.project.id).translation_last_pushed_at ==
             pushed_at

    assert TranslationSessions.get_session!(session.id).outcome == "content_hit"
  end

  test "supersession recovers completed files that have not reached a publication batch", ctx do
    {:ok, _model} =
      Glossia.LLMModels.create_model(ctx.user.account, ctx.user, %{
        "handle" => "translator",
        "model" => "openai/gpt-5",
        "api_key" => "test-checkpoint-key"
      })

    config_path = Path.join(ctx.remote, "L10N.md")

    File.write!(
      config_path,
      String.replace(File.read!(config_path), "model: openai/gpt-5", "model: translator")
    )

    File.write!(Path.join(ctx.remote, "guide.md"), "# Hello again\n")
    source = commit_source(ctx.remote)
    session = continuation(ctx, source)
    {:ok, session} = TranslationSessions.update_session_status(session, "running")
    before = sha(ctx.remote, @branch)

    batch =
      start_supervised!(
        {Glossia.TranslationSessions.PublicationBatch,
         fn changes ->
           Translate.publish_changes(%{session_id: session.id}, %{changes: changes})
         end}
      )

    repository = %{
      full_name: "glossia/demo",
      default_branch: "main",
      commit_sha: source,
      publication_branch: @branch,
      publication_commit_sha: before,
      token: "test-token"
    }

    assert {:ok, changes} =
             Glossia.Translations.RepositoryRun.run(
               session,
               ctx.user.account,
               repository,
               ["es"],
               after_item_completed: &Glossia.TranslationSessions.PublicationBatch.add(batch, &1)
             )

    assert Enum.any?(changes, &(&1.path == "es/guide.md"))
    assert count(ctx.writes) == 0
    assert sha(ctx.remote, @branch) == before

    File.write!(Path.join(ctx.remote, "README.md"), "Unrelated source change\n")
    next_source = commit_source(ctx.remote)

    assert {:ok, replacement} =
             TranslationSessions.start_continuous_session(
               ctx.project,
               %{commit_sha: next_source, source_language: "en", target_languages: ["es"]},
               enqueue: false
             )

    assert TranslationSessions.get_session!(session.id).outcome == "superseded"
    assert {:error, _} = Glossia.TranslationSessions.PublicationBatch.flush(batch)
    assert count(ctx.writes) == 0

    reject(&Glossia.Translations.translate_stream/4)
    assert :ok = Translate.run(replacement.id)
    assert count(ctx.writes) == 1
    head = sha(ctx.remote, @branch)
    assert git(ctx.remote, ["show", "#{head}:es/guide.md"]) == "# Hola again"
    lock = git(ctx.remote, ["show", "#{head}:.glossia/guide.md/es.lock"]) |> JSON.decode!()
    assert lock["source_commit_sha"] == next_source
  end

  test "a same-source continuation assesses and publishes on a manually repaired branch", ctx do
    git(ctx.remote, ["checkout", @branch])
    File.write!(Path.join(ctx.remote, "guide.md"), "# Hello repaired\n")
    git(ctx.remote, ["add", "."])
    git(ctx.remote, ["commit", "-m", "manual conflict resolution"])
    repaired = sha(ctx.remote, "HEAD")
    git(ctx.remote, ["checkout", "main"])
    session = continuation(ctx, ctx.initial.commit_sha)

    assert :ok = Translate.run(session.id)
    assert count(ctx.writes) == 1
    head = sha(ctx.remote, @branch)
    assert git(ctx.remote, ["show", "#{head}:guide.md"]) == "# Hello repaired"
    assert git(ctx.remote, ["show", "#{head}:es/guide.md"]) == "# Hola repaired"
    assert git(ctx.remote, ["rev-list", "--parents", "-n", "1", head]) == "#{head} #{repaired}"
    updated = TranslationSessions.get_session!(session.id)
    assert updated.publication_commit_sha == head
    assert updated.pull_request_number == 2
  end

  test "publishes fresh source, outputs and locks in one update and recovers a lost response",
       ctx do
    config = Application.get_env(:glossia, Glossia.TranslationSessions.PublicationBatch, [])
    Application.put_env(:glossia, Glossia.TranslationSessions.PublicationBatch, max_files: 1)

    on_exit(fn ->
      Application.put_env(:glossia, Glossia.TranslationSessions.PublicationBatch, config)
    end)

    before = sha(ctx.remote, @branch)
    File.write!(Path.join(ctx.remote, "guide.md"), "# Hello again\n")
    File.write!(Path.join(ctx.remote, "README.md"), "New source context\n")
    File.rm!(Path.join(ctx.remote, "obsolete.txt"))
    File.write!(Path.join(ctx.remote, "run.sh"), "#!/bin/sh\nexit 0\n")
    File.chmod!(Path.join(ctx.remote, "run.sh"), 0o755)
    File.ln_s!("guide.md", Path.join(ctx.remote, "current-guide"))
    File.write!(Path.join(ctx.remote, "binary.dat"), <<0, 255, 128>>)
    source = commit_source(ctx.remote)
    session = continuation(ctx, source)
    Agent.update(ctx.writes, &%{&1 | lose_response: true})

    # The final flush sees the accepted ref even though its first response was
    # lost. It must not manufacture another commit or lose the rolling PR.
    assert :ok = Translate.run(session.id)
    assert count(ctx.writes) == 1
    head = sha(ctx.remote, @branch)
    refute head == before
    assert git(ctx.remote, ["show", "#{head}:guide.md"]) == "# Hello again"
    assert git(ctx.remote, ["show", "#{head}:es/guide.md"]) == "# Hola again"
    assert git(ctx.remote, ["show", "#{head}:README.md"]) == "New source context"
    assert git(ctx.remote, ["ls-tree", head, "obsolete.txt"]) == ""
    assert git(ctx.remote, ["ls-tree", head, "run.sh"]) =~ "100755 blob"
    assert git(ctx.remote, ["ls-tree", head, "current-guide"]) =~ "120000 blob"
    assert git(ctx.remote, ["show", "#{head}:binary.dat"]) == <<0, 255, 128>>

    assert git(ctx.remote, ["rev-list", "--parents", "-n", "1", head]) ==
             "#{head} #{before} #{source}"

    lock = git(ctx.remote, ["show", "#{head}:.glossia/guide.md/es.lock"]) |> JSON.decode!()
    assert lock["source_commit_sha"] == source
    updated = TranslationSessions.get_session!(session.id)
    assert updated.publication_commit_sha == head
    assert updated.pull_request_number == 2
  end

  test "a lost-response batch can collect more pending files before retrying", ctx do
    before = sha(ctx.remote, @branch)
    File.write!(Path.join(ctx.remote, "README.md"), "New source context\n")
    source = commit_source(ctx.remote)
    session = continuation(ctx, source)
    first = [%{path: "es/first.md", status: "added", content: "Primero\n"}]
    second = [%{path: "es/second.md", status: "added", content: "Segundo\n"}]
    Agent.update(ctx.writes, &%{&1 | lose_response: true})

    assert {:error, :timeout} =
             Translate.publish_changes(%{session_id: session.id}, %{changes: first})

    accepted = sha(ctx.remote, @branch)
    assert TranslationSessions.get_session!(session.id).publication_commit_sha == before

    assert {:ok, _} =
             Translate.publish_changes(%{session_id: session.id}, %{changes: first ++ second})

    head = sha(ctx.remote, @branch)

    assert count(ctx.writes) == 2

    assert git(ctx.remote, ["rev-list", "--parents", "-n", "1", accepted]) ==
             "#{accepted} #{before} #{source}"

    assert git(ctx.remote, ["rev-list", "--parents", "-n", "1", head]) == "#{head} #{accepted}"
    assert git(ctx.remote, ["show", "#{head}:es/first.md"]) == "Primero"
    assert git(ctx.remote, ["show", "#{head}:es/second.md"]) == "Segundo"
    assert TranslationSessions.get_session!(session.id).publication_commit_sha == head
  end

  test "recovers missing PR metadata before assessing existing locks", ctx do
    before = sha(ctx.remote, @branch)
    File.write!(Path.join(ctx.remote, "README.md"), "Unrelated source\n")
    session = continuation(ctx, commit_source(ctx.remote))

    {:ok, _} =
      TranslationSessions.update_session_publication(session, %{
        publication_branch: nil,
        publication_commit_sha: nil,
        pull_request_url: nil,
        pull_request_number: nil
      })

    stub(Client, :list_pull_requests, fn _, _, _ ->
      {:ok,
       [
         %{
           "user" => %{"login" => "glossia[bot]"},
           "head" => %{
             "ref" => @branch,
             "sha" => before,
             "repo" => %{"full_name" => "glossia/demo"}
           },
           "html_url" => "https://github.com/glossia/demo/pull/2",
           "number" => 2
         }
       ]}
    end)

    reject(&Glossia.Translations.translate_stream/4)
    assert :ok = Translate.run(session.id)
    assert count(ctx.writes) == 0
    assert sha(ctx.remote, @branch) == before
    assert TranslationSessions.get_session!(session.id).pull_request_number == 2
  end

  test "cancellation during translation prevents source and output publication", ctx do
    before = sha(ctx.remote, @branch)
    File.write!(Path.join(ctx.remote, "guide.md"), "# Hello again\n")
    session = continuation(ctx, commit_source(ctx.remote))

    stub(Glossia.Translations, :translate_stream, fn _, payload, _, _ ->
      {:ok, _} = TranslationSessions.update_session_status(session, "cancelled")
      text = TranslationStubs.respond(payload, &String.replace(&1, "Hello", "Hola"))
      {:ok, %{text: text, model: "openai/gpt-5", provider: "openai"}}
    end)

    assert :ok = Translate.run(session.id)
    assert count(ctx.writes) == 0
    assert sha(ctx.remote, @branch) == before
    assert TranslationSessions.get_session!(session.id).status == "cancelled"
  end

  test "local source conflicts leave the existing publication unchanged", ctx do
    before = sha(ctx.remote, @branch)
    git(ctx.remote, ["checkout", @branch])
    File.write!(Path.join(ctx.remote, "guide.md"), "# Branch edit\n")
    git(ctx.remote, ["add", "."])
    git(ctx.remote, ["commit", "-m", "edit on PR"])
    edited = sha(ctx.remote, "HEAD")
    git(ctx.remote, ["checkout", "main"])
    File.write!(Path.join(ctx.remote, "guide.md"), "# Source edit\n")
    source = commit_source(ctx.remote)
    session = continuation(ctx, source)

    assert {:error, :translation_branch_conflict} = Translate.run(session.id)
    assert count(ctx.writes) == 0
    assert sha(ctx.remote, @branch) == edited
    refute before == edited
    assert TranslationSessions.get_session!(session.id).pull_request_number == 2
  end

  for {path, kind} <- [
        {"es/guide.md", :content},
        {"L10N.md", :content},
        {"es/guide.md", :symlink}
      ] do
    @edited_path path
    @edit_kind kind

    test "a #{kind} edit to #{path} during assessment rejects stale publication, including a retry",
         ctx do
      config = Application.get_env(:glossia, Glossia.TranslationSessions.PublicationBatch, [])
      Application.put_env(:glossia, Glossia.TranslationSessions.PublicationBatch, max_files: 1)

      on_exit(fn ->
        Application.put_env(:glossia, Glossia.TranslationSessions.PublicationBatch, config)
      end)

      before = sha(ctx.remote, @branch)
      File.write!(Path.join(ctx.remote, "guide.md"), "# Hello again\n")
      session = continuation(ctx, commit_source(ctx.remote))
      test_pid = self()

      stub(Glossia.Translations, :translate_stream, fn _, payload, _, _ ->
        git(ctx.remote, ["checkout", @branch])
        path = Path.join(ctx.remote, @edited_path)

        if @edit_kind == :symlink do
          File.rm!(path)
          File.ln_s!("# Hola again\n", path)
        else
          File.write!(path, File.read!(path) <> "\nHuman edit\n")
        end

        git(ctx.remote, ["add", "."])
        git(ctx.remote, ["commit", "-m", "human edit while translating"])
        send(test_pid, {:human_head, sha(ctx.remote, "HEAD")})
        git(ctx.remote, ["checkout", "main"])
        text = TranslationStubs.respond(payload, &String.replace(&1, "Hello", "Hola"))
        {:ok, %{text: text, model: "openai/gpt-5", provider: "openai"}}
      end)

      assert {:error, {:translation_publication_failed, :translation_branch_conflict}} =
               Translate.run(session.id)

      assert_received {:human_head, human_head}
      assert sha(ctx.remote, @branch) == human_head

      if @edit_kind == :symlink do
        assert git(ctx.remote, ["ls-tree", human_head, @edited_path]) =~ "120000 blob"
      else
        assert git(ctx.remote, ["show", "#{human_head}:#{@edited_path}"]) =~ "Human edit"
      end

      assert count(ctx.writes) == 0
      assert TranslationSessions.get_session!(session.id).publication_commit_sha == before
    end
  end

  test "a same-source continuation starts fresh after its PR was deliberately closed", ctx do
    source = ctx.initial.commit_sha
    rejected = "glossia/translate-#{String.slice(source, 0, 12)}"
    rejected_head = sha(ctx.remote, @branch)
    git(ctx.remote, ["branch", "-m", @branch, rejected])

    {:ok, _} =
      TranslationSessions.update_session_publication(
        TranslationSessions.get_session!(ctx.initial.id),
        %{publication_branch: rejected}
      )

    session = continuation(ctx, source)

    stub(Client, :get_pull_request, fn _, 2, _ ->
      {:ok, %{"state" => "closed", "merged" => false}}
    end)

    expect(Glossia.Translations, :translate_stream, fn _, payload, _, _ ->
      text = TranslationStubs.respond(payload, &String.replace(&1, "Hello", "Hola nueva"))
      {:ok, %{text: text, model: "openai/gpt-5", provider: "openai"}}
    end)

    expect(Client, :create_pull_request, fn _, %{head: branch}, _ ->
      refute branch == rejected
      {:ok, %{"html_url" => "https://github.com/glossia/demo/pull/3", "number" => 3}}
    end)

    assert :ok = Translate.run(session.id)
    updated = TranslationSessions.get_session!(session.id)
    assert updated.pull_request_number == 3
    refute updated.publication_branch == rejected
    assert sha(ctx.remote, rejected) == rejected_head

    assert git(ctx.remote, ["show", "#{updated.publication_commit_sha}:es/guide.md"]) ==
             "# Hola nueva"

    assert git(ctx.remote, ["merge-base", rejected_head, updated.publication_commit_sha]) ==
             source

    assert count(ctx.writes) == 1
  end

  test "an orphaned accepted ref gets its missing PR even when assessment is a no-op", ctx do
    source = ctx.initial.commit_sha
    orphan = "glossia/translate-#{String.slice(source, 0, 12)}"
    head = sha(ctx.remote, @branch)
    git(ctx.remote, ["branch", "-m", @branch, orphan])
    session = continuation(ctx, source)

    {:ok, _} =
      TranslationSessions.update_session_publication(session, %{
        publication_branch: nil,
        publication_commit_sha: nil,
        pull_request_url: nil,
        pull_request_number: nil
      })

    pushed_at = Repo.get!(Glossia.Accounts.Project, ctx.project.id).translation_last_pushed_at
    reject(&Glossia.Translations.translate_stream/4)

    expect(Client, :create_pull_request, fn _, %{head: ^orphan}, _ ->
      {:ok, %{"html_url" => "https://github.com/glossia/demo/pull/3", "number" => 3}}
    end)

    assert :ok = Translate.run(session.id)
    assert sha(ctx.remote, orphan) == head
    assert count(ctx.writes) == 0
    updated = TranslationSessions.get_session!(session.id)
    assert updated.publication_commit_sha == head
    assert updated.pull_request_number == 3

    assert Repo.get!(Glossia.Accounts.Project, ctx.project.id).translation_last_pushed_at ==
             pushed_at
  end

  defp continuation(ctx, source) do
    previous = TranslationSessions.get_session!(ctx.initial.id)

    {:ok, session} =
      TranslationSessions.create_session(ctx.user.account, ctx.project, %{
        commit_sha: source,
        source_language: "en",
        target_languages: ["es"],
        continued_from_session_id: previous.id,
        publication_branch: previous.publication_branch,
        publication_commit_sha: previous.publication_commit_sha,
        pull_request_number: previous.pull_request_number,
        pull_request_url: previous.pull_request_url
      })

    session
  end

  defp commit_source(remote) do
    git(remote, ["add", "."])
    git(remote, ["commit", "-m", "advance source"])
    sha(remote, "HEAD")
  end

  defp github(remote, writes) do
    stub(Glossia.Github.App, :installation_token, fn 42 -> {:ok, "test-token"} end)
    stub(Client, :get_pull_request, fn _, 2, _ -> {:ok, %{"state" => "open"}} end)
    stub(Client, :update_pull_request, fn _, _, _, _ -> {:ok, %{}} end)
    stub(Client, :list_pull_requests, fn _, _, _ -> {:ok, []} end)
    stub(Client, :create_pull_request, fn _, _, _ -> flunk("unexpected new pull request") end)

    stub(Client, :get_ref, fn _, "heads/" <> branch, _ ->
      branches =
        git(remote, ["for-each-ref", "--format=%(refname:short)", "refs/heads"])
        |> String.split("\n")

      if branch in branches,
        do: {:ok, %{"object" => %{"sha" => sha(remote, branch)}}},
        else: {:error, {:api_error, 404, %{}}}
    end)

    stub(Client, :compare_commits, fn _, base, head, _ ->
      assert git(remote, ["merge-base", base, head]) == base
      {:ok, %{"status" => if(base == head, do: "identical", else: "ahead")}}
    end)

    # Real Git object/ref storage behind the GitHub boundary. No translation,
    # checkout, merge, tree building, database or batching code is replaced.
    stub(Client, :get_commit, fn _, commit, _ ->
      {:ok, %{"tree" => %{"sha" => sha(remote, "#{commit}^{tree}")}}}
    end)

    stub(Client, :create_blob, fn _, %{content: content}, _ ->
      path = Path.join(Path.dirname(remote), "blob")
      File.write!(path, Base.decode64!(content))
      {:ok, %{"sha" => git(remote, ["hash-object", "-w", path])}}
    end)

    stub(Client, :create_tree, fn _, %{base_tree: base, tree: entries}, _ ->
      git(remote, ["read-tree", base])

      for entry <- entries do
        if entry.sha do
          git(remote, ["update-index", "--add", "--cacheinfo", entry.mode, entry.sha, entry.path])
        else
          git(remote, ["update-index", "--force-remove", "--", entry.path])
        end
      end

      tree = git(remote, ["write-tree"])
      git(remote, ["read-tree", "main"])
      {:ok, %{"sha" => tree}}
    end)

    stub(Client, :create_commit, fn _, %{tree: tree, parents: parents, message: message}, _ ->
      args = ["commit-tree", tree, "-m", message] ++ Enum.flat_map(parents, &["-p", &1])
      {:ok, %{"sha" => git(remote, args)}}
    end)

    stub(Client, :create_branch, fn _, branch, head, _ ->
      git(remote, ["update-ref", "refs/heads/#{branch}", head, String.duplicate("0", 40)])
      Agent.update(writes, &%{&1 | count: &1.count + 1})
      {:ok, %{}}
    end)

    stub(Client, :update_ref, fn _, "heads/" <> branch, head, _ ->
      before = sha(remote, branch)
      git(remote, ["merge-base", "--is-ancestor", before, head])
      git(remote, ["update-ref", "refs/heads/#{branch}", head, before])

      lost? =
        Agent.get_and_update(
          writes,
          &{&1.lose_response, %{count: &1.count + 1, lose_response: false}}
        )

      if lost?, do: {:error, :timeout}, else: {:ok, %{}}
    end)

    # Only used by the unchanged implementation in the before run.
    stub(Client, :merge_branch, fn _, %{base: base, head: source}, token ->
      before = sha(remote, base)
      tree = git(remote, ["merge-tree", "--write-tree", before, source])
      head = git(remote, ["commit-tree", tree, "-p", before, "-p", source, "-m", "source sync"])
      {:ok, _} = Client.update_ref("glossia/demo", "heads/#{base}", head, token)
      {:ok, %{"sha" => head}}
    end)
  end

  defp sha(remote, ref), do: git(remote, ["rev-parse", ref])
  defp count(writes), do: Agent.get(writes, & &1.count)

  defp git(remote, args) do
    {output, status} =
      MuonTrap.cmd(
        "git",
        [
          "-c",
          "user.name=Tester",
          "-c",
          "user.email=test@example.com",
          "-c",
          "commit.gpgsign=false",
          "-c",
          "core.hooksPath=/dev/null",
          "-C",
          remote | args
        ],
        into: "",
        stderr_to_stdout: true,
        timeout: 10_000
      )

    assert status == 0, "git #{inspect(args)} failed: #{output}"
    String.trim(output)
  end
end
