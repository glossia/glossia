defmodule Glossia.Editor.PreviewTest do
  use Glossia.DataCase, async: false
  use Mimic

  alias Glossia.{Editor, Projects, Sandboxes, TestHelpers}
  alias Glossia.Editor.{Content, Preview, PreviewRuntime}
  alias Glossia.Editor.File, as: EditorFile
  alias Glossia.Github.App
  alias Glossia.Sandbox.LocalAdapter

  setup :set_mimic_global
  @moduletag :tmp_dir

  setup c do
    old = Application.get_env(:glossia, Preview)
    old_sandbox = Application.get_env(:glossia, Glossia.Sandbox)
    Application.put_env(:glossia, Glossia.Sandbox, adapter: LocalAdapter)

    on_exit(fn ->
      if old,
        do: Application.put_env(:glossia, Preview, old),
        else: Application.delete_env(:glossia, Preview)

      if old_sandbox,
        do: Application.put_env(:glossia, Glossia.Sandbox, old_sandbox),
        else: Application.delete_env(:glossia, Glossia.Sandbox)
    end)

    user =
      TestHelpers.create_user("preview-#{System.unique_integer([:positive])}@test.com", "preview")

    installation =
      Repo.insert!(%Glossia.Accounts.GithubInstallation{
        account_id: user.account.id,
        github_installation_id: System.unique_integer([:positive]),
        github_account_login: "fixture",
        github_account_type: "User",
        github_account_id: 42
      })

    {:ok, project} = Projects.create_project(user.account, %{handle: "preview", name: "Preview"})

    project =
      project
      |> change(%{
        github_installation_id: installation.id,
        github_repo_full_name: "fixture/preview",
        github_repo_default_branch: "main"
      })
      |> Repo.update!()
      |> Repo.preload(:account)

    stub(App, :installation_token, fn _ -> {:ok, "DO-NOT-EXPOSE-GITHUB-TOKEN"} end)

    root = Path.join(c.tmp_dir, "repository")
    File.mkdir_p!(Path.join(root, "es"))
    File.write!(Path.join(root, "es/products.json"), ~s({"title":"Original product","count":7}))
    File.write!(Path.join(root, "es/guide.md"), "# Original guide\n\nA real Markdown page.\n")
    File.write!(Path.join(root, "es/info.yaml"), "title: Original YAML\ncount: 7\n")
    File.write!(Path.join(root, "server.mjs"), server())
    File.write!(Path.join(root, "package.json"), ~s({"scripts":{"dev":"node server.mjs"}}))
    git(root, ["init", "-q", "-b", "main"])
    git(root, ["add", "."])

    git(root, [
      "-c",
      "user.name=Fixture",
      "-c",
      "user.email=fixture@test.com",
      "commit",
      "-qm",
      "fixture"
    ])

    files =
      for {path, format} <- [
            {"es/products.json", "json"},
            {"es/guide.md", "markdown"},
            {"es/info.yaml", "yaml"}
          ] do
        {sha, 0} =
          MuonTrap.cmd("git", ["-C", root, "rev-parse", "HEAD:" <> path],
            into: "",
            timeout: 10_000
          )

        Repo.insert!(%EditorFile{
          project_id: project.id,
          path: path,
          source_path: path,
          locale: "es",
          format: format,
          content: File.read!(Path.join(root, path)),
          blob_sha: String.trim(sha)
        })
      end

    discovery = fn adapter, id, repo, file ->
      # Only the model provider is replaced. Inspect actual checkout source
      # and verify credentials/remotes were removed before starting any code.
      {:error, :enoent} = adapter.download_file(id, Path.join(repo, ".git/config"))
      {:ok, source} = adapter.download_file(id, Path.join(repo, "server.mjs"))
      true = String.contains?(source, file.path)
      {:ok, fields} = Content.fields(file.format, file.draft_content || file.content)

      evidence =
        fields
        |> hd()
        |> Map.fetch!(:value)
        |> String.split("\n")
        |> hd()
        |> String.trim_leading("# ")

      route =
        %{"json" => "/es/products", "markdown" => "/es/guide", "yaml" => "/es/info"}[file.format]

      adapter.upload_file(
        id,
        Path.join(Path.dirname(repo), "preview-manifest.json"),
        JSON.encode!(%{
          command: "exec npm run dev",
          path: route,
          evidence: evidence,
          reason: "server.mjs maps this locale route to this content file"
        })
      )
    end

    chromium =
      System.get_env("GLOSSIA_PREVIEW_CHROMIUM") || System.find_executable("chromium") ||
        "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"

    config = [
      trusted_local: true,
      local_repository: root,
      trusted_discovery: discovery,
      local_port: 14173,
      local_browser_port: 19222,
      chromium: chromium
    ]

    Application.put_env(:glossia, Preview, config)
    %{fixture: %{user: user, project: project, file: hd(files), files: files, config: config}}
  end

  test "local execution fails closed and no sandbox is reserved", c do
    c = c.fixture
    Application.put_env(:glossia, Preview, [])

    assert {:error, :preview_requires_isolation} =
             Preview.start(c.user, c.project, c.file.id, self())

    assert {:error, :preview_requires_isolation} =
             LocalAdapter.execute_preview("unused", "true", [])

    assert Repo.all(Glossia.Sandboxes.Sandbox) == []
  end

  test "authorization, project scope and frozen snapshots are enforced", c do
    c = c.fixture
    assert {:error, _} = Preview.start(nil, c.project, c.file.id, self())
    {:ok, other} = Projects.create_project(c.user.account, %{handle: "other", name: "Other"})

    assert {:error, :not_found} =
             Preview.start(c.user, %{other | account: c.user.account}, c.file.id, self())

    Repo.update!(change(c.file, conflict: true))
    assert {:error, :repository_changed} = Preview.start(c.user, c.project, c.file.id, self())
  end

  test "updates are nonblocking, bounded, revisioned, and only adopt identical saves", c do
    c = c.fixture
    block_discovery(c)
    {:ok, pid} = Preview.start(c.user, c.project, c.file.id, self())
    assert_receive {:discovery_waiting, worker, _id}, 10_000
    {:ok, [field]} = Content.fields(c.file.format, c.file.content)
    assert {:ok, 1} = Preview.update(pid, c.file.id, 1, %{field.id => "Accepted product"})
    assert {:error, :stale} = Preview.update(pid, c.file.id, 0, %{})
    assert {:error, _} = Preview.update(pid, c.file.id, 1, %{"unknown" => "bad"})

    assert {:error, :file_too_large} =
             Preview.update(pid, c.file.id, 1, %{field.id => String.duplicate("x", 1_000_001)})

    {:ok, saved} = Editor.save(c.user, c.project, c.file.id, 1, %{field.id => "Accepted product"})
    assert {:ok, 2} = Preview.update(pid, c.file.id, saved.lock_version, %{})

    {:ok, foreign} =
      Editor.save(c.user, c.project, c.file.id, saved.lock_version, %{
        field.id => "Someone else's product"
      })

    assert {:error, :stale} = Preview.update(pid, c.file.id, foreign.lock_version, %{})

    # An old browser result arriving after acceptance cannot become current.
    send(
      pid,
      {:preview_event, worker, %{status: :ready, message: "old", revision: 1, frame: "old"}}
    )

    refute_receive {:editor_preview, ^pid, %{frame: "old"}}, 50
    assert :ok = Preview.stop(pid)
    assert :ok = Preview.stop(pid)
    wait_terminated(c.project)
  end

  test "owner death, absolute and idle deadlines delete the sandbox", c do
    c = c.fixture

    for reason <- [:owner, :absolute, :idle] do
      block_discovery(c)

      owner =
        spawn(fn ->
          receive do
            :done -> :ok
          end
        end)

      {:ok, pid} = Preview.start(c.user, c.project, c.file.id, owner)
      monitor = Process.monitor(pid)
      assert_receive {:discovery_waiting, _worker, _id}, 10_000

      case reason do
        :owner -> send(owner, :done)
        :absolute -> send(pid, :absolute_deadline)
        :idle -> send(pid, {:timeout, :sys.get_state(pid).idle, :idle_deadline})
      end

      assert_receive {:DOWN, ^monitor, :process, ^pid, :normal}, 2_000
      send(owner, :done)
      wait_terminated(c.project)
    end
  end

  test "pointer input is owner-bound, revisioned, authorized and bounded", c do
    c = c.fixture
    block_discovery(c)
    {:ok, pid} = Preview.start(c.user, c.project, c.file.id, self())
    assert_receive {:discovery_waiting, worker, _}, 10_000
    click = %{"type" => "click", "x" => 10, "y" => 20}
    assert {:error, :not_ready} = Preview.interact(pid, 0, click)
    assert {:error, :stale} = Preview.interact(pid, 1, click)
    assert {:error, :stale} = Preview.interact(pid, "0", click)

    assert {:error, :not_owner} =
             Task.async(fn -> Preview.interact(pid, 0, click) end) |> Task.await()

    for input <- [
          nil,
          %{type: "click", x: 1, y: 1},
          %{click | "type" => "tap"},
          %{click | "x" => -1},
          %{click | "x" => 1200},
          %{click | "y" => 800},
          %{click | "x" => 1.5},
          Map.put(click, "extra", true),
          %{click | "type" => "scroll"},
          Map.merge(click, %{"type" => "scroll", "delta_x" => 0, "delta_y" => 2001})
        ] do
      assert {:error, :invalid_input} = Preview.interact(pid, 0, input)
    end

    send(pid, {:preview_event, worker, %{status: :ready, frame: "fixture", revision: 0}})
    assert_receive {:editor_preview, ^pid, %{frame: "fixture"}}, 1_000
    for _ <- 1..32, do: assert(:ok = Preview.interact(pid, 0, click))
    assert {:error, :busy} = Preview.interact(pid, 0, click)
    send(pid, {:preview_input_ack, worker, 32})

    assert :ok =
             Preview.interact(pid, 0, %{
               "type" => "scroll",
               "x" => 1199,
               "y" => 799,
               "delta_x" => -2000,
               "delta_y" => 2000
             })

    assert {:ok, 1} = Preview.update(pid, c.file.id, c.file.lock_version, %{})
    assert {:error, :stale} = Preview.interact(pid, 0, click)
    assert {:error, :not_ready} = Preview.interact(pid, 1, click)
    send(pid, {:preview_event, worker, %{status: :ready, frame: "current", revision: 1}})
    assert_receive {:editor_preview, ^pid, %{frame: "current"}}, 1_000
    Repo.update!(change(c.file, conflict: true))
    assert {:error, :unauthorized} = Preview.interact(pid, 1, click)
    assert :ok = Preview.stop(pid)
    assert {:error, :stopped} = Preview.interact(pid, 1, click)
    wait_terminated(c.project)
  end

  test "viewing fresh frames refreshes idle timeout and ignores an obsolete timer", c do
    c = c.fixture
    block_discovery(c)
    {:ok, pid} = Preview.start(c.user, c.project, c.file.id, self())
    assert_receive {:discovery_waiting, worker, _}, 10_000
    old = :sys.get_state(pid).idle

    send(
      pid,
      {:preview_event, worker, %{status: :ready, message: "frame", revision: 0, frame: "fixture"}}
    )

    assert_receive {:editor_preview, ^pid, %{frame: "fixture"}}, 1_000
    send(pid, {:timeout, old, :idle_deadline})
    assert Process.alive?(pid)
    assert :ok = Preview.stop(pid)
    wait_terminated(c.project)
  end

  test "discovery failures are safe and clean up", c do
    c = c.fixture

    Application.put_env(
      :glossia,
      Preview,
      Keyword.put(c.config, :trusted_discovery, fn adapter, id, root, _ ->
        adapter.upload_file(
          id,
          Path.join(Path.dirname(root), "preview-manifest.json"),
          ~s({"error":"missing_credentials"})
        )
      end)
    )

    {:ok, pid} = Preview.start(c.user, c.project, c.file.id, self())
    assert_receive {:editor_preview, ^pid, %{status: :error, message: message}}, 10_000
    assert message =~ "credentials"
    refute message =~ "DO-NOT-EXPOSE"
    wait_terminated(c.project)
  end

  test "routes and file paths cannot become proxy destinations or escape checkout" do
    for path <- [
          "https://evil.test/x",
          "//evil.test",
          "/%2fexternal.test",
          "/\\external.test",
          "/x%0aHeader",
          "/x#fragment",
          "relative"
        ] do
      refute PreviewRuntime.valid_route?(path), path
    end

    assert PreviewRuntime.valid_route?("/es/products?view=card")

    for path <- ["../secret", "/etc/passwd", ".git/config", "a/../../secret", "x\\secret"] do
      refute PreviewRuntime.valid_file_path?(path), path
    end

    assert PreviewRuntime.valid_file_path?("es/products.json")
  end

  test "manifest requires route evidence from the edited content", c do
    c = c.fixture

    manifest = %{
      "command" => "node server.mjs",
      "path" => "/es/products",
      "evidence" => "Original product",
      "reason" => "source mapping"
    }

    assert {:ok, _} = PreviewRuntime.validate_manifest(manifest, c.file)

    assert {:error, :ambiguous_route} =
             PreviewRuntime.validate_manifest(
               %{manifest | "evidence" => "Unrelated homepage"},
               c.file
             )

    assert {:error, :ambiguous_route} =
             PreviewRuntime.validate_manifest(%{manifest | "path" => "//evil.test"}, c.file)
  end

  test "preview sandbox APIs do not expose agent authentication files", c do
    c = c.fixture

    {:ok, sandbox} =
      Sandboxes.create_sandbox(c.user.account, c.project, %{purpose: "editor_preview"})

    assert {:error, :sandbox_operation_not_allowed} =
             Sandboxes.read_file(sandbox, ".glossia-harness/auth.json")

    assert {:error, :sandbox_operation_not_allowed} =
             Sandboxes.write_file(sandbox, "preview-input.json", "{}")

    assert {:error, :sandbox_operation_not_allowed} =
             Sandboxes.execute_sandbox(sandbox, "echo unsafe")

    assert {:ok, _} = Sandboxes.destroy_sandbox(sandbox)
  end

  test "preview uses the account quota and fails safely on a moved repository base", c do
    c = c.fixture
    sandbox_config = Application.get_env(:glossia, Glossia.Sandbox)

    Application.put_env(
      :glossia,
      Glossia.Sandbox,
      Keyword.put(sandbox_config, :max_active_per_account, 0)
    )

    {:ok, quota_pid} = Preview.start(c.user, c.project, c.file.id, self())
    assert_receive {:editor_preview, ^quota_pid, %{status: :error, message: quota_message}}, 5_000
    assert quota_message =~ "sandbox limit"
    Application.put_env(:glossia, Glossia.Sandbox, sandbox_config)

    Repo.update!(change(c.file, content: ~s({"title":"Remote has changed","count":7})))
    {:ok, stale_pid} = Preview.start(c.user, c.project, c.file.id, self())
    assert_receive {:editor_preview, ^stale_pid, %{status: :error, message: message}}, 10_000
    assert message =~ "repository no longer matches"
    wait_terminated(c.project)
  end

  test "preview downloads are bounded before loading arbitrary sandbox files", c do
    c = c.fixture

    {:ok, sandbox} =
      Sandboxes.create_sandbox(c.user.account, c.project, %{purpose: "editor_preview"})

    {:ok, root} = LocalAdapter.repo_path(sandbox.id)
    path = Path.join(root, "large")
    assert :ok = LocalAdapter.upload_file(sandbox.id, path, String.duplicate("x", 1_001))
    assert {:error, :file_too_large} = LocalAdapter.download_preview_file(sandbox.id, path, 1_000)
    assert {:ok, bytes} = LocalAdapter.download_preview_file(sandbox.id, path, 1_001)
    assert byte_size(bytes) == 1_001
    assert {:ok, _} = Sandboxes.destroy_sandbox(sandbox)
  end

  # Run with:
  # GLOSSIA_PREVIEW_CHROMIUM='/path/to/chromium' mise exec -- mix test test/glossia/editor/preview_test.exs --include live
  # Model discovery ONLY is deterministic. Clone, quota/deadline lifecycle,
  # serialization, server, CDP/Chromium rendering and downloaded JPEGs are real.
  @tag :live
  @tag timeout: 120_000
  test "Chromium preserves rapid click, navigation and wheel scroll across frames", c do
    c = c.fixture
    {:ok, pid} = Preview.start(c.user, c.project, c.file.id, self())
    first = frame(pid, 0)
    assert :ok = Preview.interact(pid, 0, %{"type" => "click", "x" => 60, "y" => 40})

    assert :ok =
             Preview.interact(pid, 0, %{
               "type" => "scroll",
               "x" => 600,
               "y" => 400,
               "delta_x" => 0,
               "delta_y" => 600
             })

    sandbox =
      Repo.one!(
        from s in Glossia.Sandboxes.Sandbox,
          where: s.project_id == ^c.project.id and s.status == "ready"
      )

    {:ok, root} = LocalAdapter.repo_path(sandbox.id)
    state = interaction_state(sandbox.id, root)
    assert state["clicks"] == 1
    assert state["y"] >= 500
    assert state["path"] == "/es/interactive?clicked=1"
    changed = frame(pid, 0)
    refute changed.frame == first.frame

    for _ <- 1..3 do
      frame(pid, 0)
      assert interaction_state(sandbox.id, root) == state
    end

    # Continuous gestures must keep streaming and release input capacity.
    streamed =
      Enum.reduce(1..40, 0, fn _, frames ->
        assert :ok =
                 Preview.interact(pid, 0, %{
                   "type" => "scroll",
                   "x" => 600,
                   "y" => 400,
                   "delta_x" => 0,
                   "delta_y" => 2
                 })

        Process.sleep(150)

        receive do
          {:editor_preview, ^pid, %{frame: _, revision: 0}} -> frames + 1
        after
          0 -> frames
        end
      end)

    assert streamed >= 2
    assert {:ok, 1} = Preview.update(pid, c.file.id, c.file.lock_version, %{})

    assert {:error, :stale} =
             Preview.interact(pid, 0, %{"type" => "click", "x" => 60, "y" => 40})

    frame(pid, 1)
    assert :ok = Preview.stop(pid)
    wait_terminated(c.project)
    wait_ports_closed([14173, 19222])
  end

  @tag :live
  @tag timeout: 120_000
  test "real repository app renders non-home JSON, Markdown and YAML edits to JPEG frames", c do
    c = c.fixture

    for file <- c.files do
      {:ok, pid} = Preview.start(c.user, c.project, file.id, self())
      first = frame(pid, 0)
      assert first.path != "/"
      assert <<255, 216, _::binary>> = Base.decode64!(first.frame)
      {:ok, fields} = Content.fields(file.format, file.content)
      field = hd(fields)

      for n <- 1..8 do
        assert {:ok, ^n} =
                 Preview.update(pid, file.id, file.lock_version, %{
                   field.id => "Changed #{file.format} #{n}"
                 })
      end

      changed = frame(pid, 8)
      refute changed.frame == first.frame

      sandbox =
        Repo.one!(
          from s in Glossia.Sandboxes.Sandbox,
            where: s.project_id == ^c.project.id and s.status == "ready"
        )

      {:ok, root} = LocalAdapter.repo_path(sandbox.id)
      {:ok, checkout_content} = LocalAdapter.download_file(sandbox.id, Path.join(root, file.path))
      {:ok, checked_fields} = Content.fields(file.format, checkout_content)
      assert hd(checked_fields).value == "Changed #{file.format} 8"
      if file.format == "json", do: assert(Jason.decode!(checkout_content)["count"] == 7)

      for other <- c.files, other.id != file.id do
        {:ok, current} = Editor.get_file(c.user, c.project, other.id)
        assert {:ok, bytes} = LocalAdapter.download_file(sandbox.id, Path.join(root, other.path))
        assert bytes == (current.draft_content || current.content)
      end

      {:ok, saved} =
        Editor.save(c.user, c.project, file.id, file.lock_version, %{
          field.id => "Changed #{file.format} 8"
        })

      assert {:ok, 9} = Preview.update(pid, file.id, saved.lock_version, %{})
      assert frame(pid, 9).path == first.path
      assert :ok = Preview.stop(pid)
      wait_terminated(c.project)
      wait_ports_closed([14173, 19222])
    end
  end

  defp block_discovery(c) do
    parent = self()

    Application.put_env(
      :glossia,
      Preview,
      Keyword.put(c.config, :trusted_discovery, fn _, id, _, _ ->
        send(parent, {:discovery_waiting, self(), id})

        receive do
          :never -> :ok
        end
      end)
    )
  end

  defp interaction_state(id, root, attempts \\ 100)
  defp interaction_state(_, _, 0), do: flunk("Chromium did not click and scroll")

  defp interaction_state(id, root, attempts) do
    with {:ok, bytes} <- LocalAdapter.download_file(id, Path.join(root, "interaction.json")),
         {:ok, %{"clicks" => 1, "y" => y} = state} <- JSON.decode(bytes),
         true <- y >= 500 do
      state
    else
      _ ->
        Process.sleep(100)
        interaction_state(id, root, attempts - 1)
    end
  end

  defp frame(pid, revision) do
    receive do
      {:editor_preview, ^pid, %{status: :error} = event} ->
        flunk("Preview failed: #{inspect(event)}")

      {:editor_preview, ^pid, %{frame: _, revision: ^revision} = event} ->
        event

      {:editor_preview, ^pid, _} ->
        frame(pid, revision)
    after
      30_000 -> flunk("No actual Chromium frame for revision #{revision}")
    end
  end

  defp wait_terminated(project, attempts \\ 100)
  defp wait_terminated(_, 0), do: flunk("Preview sandbox was not terminated")

  defp wait_terminated(project, attempts) do
    remaining =
      Repo.all(
        from s in Glossia.Sandboxes.Sandbox,
          where: s.project_id == ^project.id and s.status in ["pending", "ready", "terminating"]
      )

    if remaining != [] do
      Process.sleep(50)
      wait_terminated(project, attempts - 1)
    end
  end

  defp git(root, args) do
    assert {_, 0} = MuonTrap.cmd("git", ["-C", root | args], into: "", timeout: 10_000)
  end

  defp wait_ports_closed(ports, attempts \\ 100)
  defp wait_ports_closed(_, 0), do: flunk("Preview app or browser still listens after Stop")

  defp wait_ports_closed(ports, attempts) do
    closed? =
      Enum.all?(ports, fn port ->
        case :gen_tcp.connect(~c"127.0.0.1", port, [:binary, active: false], 100) do
          {:error, :econnrefused} ->
            true

          {:ok, socket} ->
            :gen_tcp.close(socket)
            false

          _ ->
            false
        end
      end)

    unless closed? do
      Process.sleep(50)
      wait_ports_closed(ports, attempts - 1)
    end
  end

  defp server do
    ~S"""
    import http from 'node:http';
    import fs from 'node:fs';
    const escape = s => s.replaceAll('&','&amp;').replaceAll('<','&lt;');
    http.createServer((req,res) => {
      if (req.url.startsWith('/state?')) {
        const params = new URL(req.url, 'http://localhost').searchParams;
        fs.writeFileSync('interaction.json', JSON.stringify({clicks: Number(params.get('clicks')), y: Number(params.get('y')), path: params.get('path')}));
        res.end('ok'); return;
      }
      let content;
      if (req.url === '/es/products') content = JSON.parse(fs.readFileSync('es/products.json', 'utf8')).title;
      else if (req.url === '/es/guide') content = fs.readFileSync('es/guide.md', 'utf8').replace(/^# /, '');
      else if (req.url === '/es/info') {
        const raw = fs.readFileSync('es/info.yaml', 'utf8').match(/^title: (.+)$/m)[1];
        content = raw.startsWith('"') ? JSON.parse(raw) : raw;
      } else { res.writeHead(404); res.end('Not a preview page'); return; }
      // Verify that neither host secrets nor clone/model credentials reached
      // repository execution. Node has an intentionally minimal environment.
      if (process.env.GITHUB_TOKEN || process.env.DATABASE_URL || fs.existsSync('.git')) process.exit(4);
      res.setHeader('Content-Type','text/html; charset=utf-8');
      res.end('<!doctype html><html><body style="font:32px sans-serif;min-height:3000px;background:linear-gradient(white,steelblue)"><button id="click" style="position:fixed;left:20px;top:20px;width:120px;height:50px">Click me</button><h1 style="margin-top:120px">' + escape(content) + '</h1><script>let clicks=0;function report(){fetch("/state?"+new URLSearchParams({clicks,y:scrollY,path:location.pathname+location.search}))}document.querySelector("button").onclick=()=>{clicks++;document.querySelector("button").textContent="Clicked "+clicks;history.pushState({},"","/es/interactive?clicked="+clicks);report()};addEventListener("scroll",report);report();</script></body></html>');
    }).listen(Number(process.env.PORT), process.env.HOST);
    """
  end
end
