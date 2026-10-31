defmodule Glossia.SandboxBench.Reconciler do
  @moduledoc "Single-writer fixed-workload experiment, not a production operator."
  alias Glossia.SandboxBench, as: Bench

  @finalizer "bench.glossia.ai/cleanup"
  @label "app.kubernetes.io/name=glossia-gvisor-bench"
  @account "/var/run/secrets/kubernetes.io/serviceaccount"

  def run do
    File.mkdir_p!("/state")
    File.chmod!("/state", 0o700)
    {:ok, _} = Task.Supervisor.start_link(name: __MODULE__.Tasks, max_children: 2)
    poll(%{})
  end

  defp poll(pending) do
    pending =
      try do
        resources =
          request(:get, collection() <> "?" <> URI.encode_query(%{"labelSelector" => @label}))[
            "items"
          ]

        Enum.reduce(resources, pending, fn resource, tasks ->
          uid = resource["metadata"]["uid"]

          if tasks[uid] && Process.alive?(tasks[uid]) do
            tasks
          else
            case Task.Supervisor.start_child(__MODULE__.Tasks, fn ->
                   reconcile_safely(resource)
                 end) do
              {:ok, pid} -> Map.put(tasks, uid, pid)
              {:error, :max_children} -> tasks
            end
          end
        end)
        |> Map.take(Enum.map(resources, & &1["metadata"]["uid"]))
      rescue
        error ->
          IO.puts("API reconciliation deferred: #{Exception.message(error)}")
          pending
      end

    Process.sleep(100)
    poll(pending)
  end

  defp collection,
    do:
      "/apis/bench.glossia.ai/v1alpha1/namespaces/#{System.fetch_env!("NAMESPACE")}/sandboxsessions"

  defp request(method, path, value \\ nil) do
    opts = [
      method: method,
      base_url: "https://kubernetes.default.svc",
      url: path,
      headers: [
        {"authorization", "Bearer " <> String.trim(File.read!(@account <> "/token"))},
        {"content-type", "application/merge-patch+json"}
      ],
      connect_options: [transport_opts: [cacertfile: @account <> "/ca.crt"]],
      receive_timeout: 10_000,
      retry: false
    ]

    response = Req.request!(if(value == nil, do: opts, else: Keyword.put(opts, :json, value)))

    if response.status not in 200..299,
      do: raise("Kubernetes #{method} #{path}: #{response.status} #{inspect(response.body)}")

    response.body
  end

  defp status(resource, values) do
    metadata = resource["metadata"]
    value = Map.merge(%{"observedGeneration" => metadata["generation"], "reason" => nil}, values)

    unless Enum.all?(value, fn {key, item} -> get_in(resource, ["status", key]) == item end) do
      request(:patch, collection() <> "/#{metadata["name"]}/status", %{
        "metadata" => %{"resourceVersion" => metadata["resourceVersion"]},
        "status" => value
      })
    end
  end

  defp load(resource) do
    uid = resource["metadata"]["uid"]

    unless Regex.match?(
             ~r/\A[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}\z/,
             uid
           ),
           do: raise("Invalid Kubernetes UID")

    directory = Path.join("/state", uid)
    File.mkdir_p!(directory)
    File.chmod!(directory, 0o700)
    journal = Path.join(directory, "journal.json")

    %{
      uid: uid,
      directory: directory,
      journal: journal,
      data: if(File.exists?(journal), do: Bench.read_json(journal), else: %{"phase" => "Empty"})
    }
  end

  defp save(session, changes) do
    data =
      Bench.write_json(
        session.journal,
        Map.merge(session.data, Map.new(changes, fn {key, value} -> {to_string(key), value} end))
      )

    %{session | data: data}
  end

  defp guest(session, args),
    do: Bench.runsc(["exec", session.data["runtime_id"] | args], timeout: 20_000)

  defp probe(session),
    do: guest(session, ["node", "/opt/glossia-bench/probe.mjs"]) |> Jason.decode!()

  defp frame_path(session),
    do: Path.join(session.data["bundle"], "rootfs/tmp/glossia/preview-frame.json")

  defp frame(session, sequence, previous \\ -1) do
    Bench.await(
      fn ->
        if Bench.processes(session.data["runtime_id"]) == [],
          do: raise("Preview runtime is no longer alive")

        if File.exists?(frame_path(session)) do
          value = Bench.read_json(frame_path(session))

          if image = Bench.decode_frame(value, previous, sequence) do
            File.write!(Path.join(session.directory, "latest.jpg"), image)
            Map.delete(value, "frame")
          end
        end
      end,
      "No fresh, input-acknowledging preview"
    )
  end

  defp create(session, title) do
    bundle = Path.join(session.directory, "active")
    runtime_id = "gsv-#{session.uid}-" <> Bench.id()
    session = save(session, phase: "Starting", runtime_id: runtime_id, bundle: bundle)
    root = Path.join(bundle, "rootfs")
    File.mkdir_p!(root)
    Bench.command("tar", ["-xpf", "/opt/bench/rootfs.tar", "-C", root])
    content = Jason.encode!(%{"title" => title})
    marker = "GlossiaBenchmark" <> Bench.id()

    config = %{
      "root" => "/tmp/glossia/repo",
      "command" => "node /opt/glossia-bench/server.mjs",
      "path" => "/es/products",
      "probe_path" => "es/products.json",
      "probe_content" => Jason.encode!(%{"title" => title <> " " <> marker}),
      "original_content" => content,
      "probe_marker" => marker,
      "evidence" => title,
      "highlight_targets" => [title]
    }

    File.cp!(
      "/opt/bench/preview-runtime.mjs",
      Path.join(root, "opt/glossia-bench/preview-runtime.mjs")
    )

    Bench.write_json(Path.join(root, "opt/glossia-bench/preview-launch.json"), config)
    Bench.command("runsc", ["spec", "--bundle=#{bundle}"])
    specification = Bench.read_json(Path.join(bundle, "config.json"))

    process =
      Map.merge(specification["process"], %{
        "terminal" => false,
        "cwd" => "/tmp/glossia/repo",
        "args" => [
          "/bin/sh",
          "-c",
          "echo $$ > /tmp/glossia/driver.pid; exec node /opt/glossia-bench/preview-runtime.mjs /opt/glossia-bench/preview-launch.json > /tmp/glossia/preview-runtime.log 2>&1"
        ],
        "env" => [
          "PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin",
          "HOME=/tmp/glossia"
        ]
      })

    Bench.write_json(
      Path.join(bundle, "config.json"),
      Map.merge(specification, %{
        "root" => %{"path" => "rootfs", "readonly" => false},
        "process" => process
      })
    )

    session = save(session, content: content)
    Bench.runsc(["create", "--bundle=#{bundle}", runtime_id])
    Bench.runsc(["start", runtime_id])
    frame = frame(session, 0)
    proof = probe(session)
    Bench.verify_continuity!(proof, proof, content, 0)

    if length(Bench.processes(runtime_id)) < 2,
      do: raise("Cannot observe both sandbox and gofer resource ownership")

    save(session, phase: "Running", proof: proof, frame: frame, input_sequence: 0)
  end

  defp click(session, sequence) do
    committed = session.data["input_sequence"]
    requested = max(sequence, session.data["requested_sequence"] || committed)

    if sequence < committed, do: raise("Input sequence must not decrease")

    # The backlog is durable, but only the in-flight batch must settle before
    # suspension. Retry that batch first: the guest skips acknowledged inputs.
    target = min(session.data["pending_sequence"] || requested, committed + 32)
    session = save(session, requested_sequence: requested)

    if target == committed do
      session
    else
      session = save(session, pending_sequence: target)

      inputs =
        Enum.map(
          (committed + 1)..target,
          &%{"sequence" => &1, "input" => %{"type" => "click", "x" => 60, "y" => 40}}
        )

      script =
        "const f=require('fs');f.writeFileSync('/tmp/glossia/preview-interactions.next',process.argv[1]);f.renameSync('/tmp/glossia/preview-interactions.next','/tmp/glossia/preview-interactions.json')"

      # Write through the guest, respecting exclusive gofer filesystem caching.
      guest(session, [
        "node",
        "-e",
        script,
        Jason.encode!(%{"revision" => 0, "inputs" => inputs})
      ])

      frame = frame(session, target, session.data["frame"]["sequence"])
      proof = probe(session)

      Bench.verify_continuity!(
        session.data["proof"],
        proof,
        session.data["content"],
        session.data["proof"]["page"]["clicks"] + target - committed
      )

      save(session, input_sequence: target, frame: frame, proof: proof, pending_sequence: nil)
    end
  end

  defp stop(session) do
    if runtime_id = session.data["runtime_id"] do
      # Delete is idempotent; never kill a numeric PID that could be reused.
      Bench.runsc(["delete", "--force", runtime_id])

      Bench.await(
        fn -> if Bench.processes(runtime_id) == [], do: true end,
        "Sandbox processes survived deletion",
        10_000
      )
    end
  end

  defp suspend(session) do
    started = Bench.now_ms()
    session = settle_input(session)
    proof = probe(session)

    Bench.verify_continuity!(
      session.data["proof"],
      proof,
      session.data["content"],
      session.data["proof"]["page"]["clicks"]
    )

    session = save(session, phase: "Quiescing")

    guest(session, [
      "node",
      "-e",
      "require('fs').writeFileSync('/tmp/glossia/checkpoint-request','pause')"
    ])

    ready = Path.join(session.data["bundle"], "rootfs/tmp/glossia/checkpoint-ready.json")

    Bench.await(
      fn -> if File.exists?(ready), do: Bench.read_json(ready) end,
      "Preview did not reach the idle checkpoint boundary",
      20_000
    )

    quiesce_ms = Bench.now_ms() - started
    before = Bench.processes(session.data["runtime_id"])
    if length(before) < 2, do: raise("Sandbox resource proof unavailable before checkpoint")
    attempt = Path.join(session.directory, "checkpoint-" <> Bench.id())
    File.mkdir!(attempt)
    File.chmod!(attempt, 0o700)
    session = save(session, phase: "Checkpointing", attempt: attempt, original_processes: before)

    Bench.runsc([
      "checkpoint",
      "--compression=none",
      "--image-path=#{attempt}/memory",
      session.data["runtime_id"]
    ])

    stop(session)
    final_frame = Bench.read_json(frame_path(session))
    image = Bench.decode_frame(final_frame, -1, session.data["input_sequence"])
    if image == nil, do: raise("Checkpoint frame does not acknowledge the committed input")
    File.write!(Path.join(session.directory, "latest.jpg"), image)
    watermark = Map.delete(final_frame, "frame")
    # Freeze ordinary files only after every writer has stopped. Memory alone
    # is not a committed checkpoint; each restore needs a writable clone.
    Bench.command("cp", [
      "-a",
      "--reflink=auto",
      session.data["bundle"],
      Path.join(attempt, "bundle")
    ])

    Bench.command("sync", ["-f", attempt])

    Bench.write_json(Path.join(attempt, "complete.json"), %{
      "runtime_version" => Bench.command("runsc", ["--version"]),
      "proof" => proof,
      "frame" => watermark,
      "original_processes" => before
    })

    save(session,
      phase: "Suspended",
      proof: proof,
      frame: watermark,
      checkpoint: attempt,
      quiesce_ms: quiesce_ms,
      suspend_ms: Bench.now_ms() - started
    )
  end

  defp resume(session) do
    checkpoint = session.data["checkpoint"]
    completion = Bench.read_json(Path.join(checkpoint, "complete.json"))

    if completion["runtime_version"] != Bench.command("runsc", ["--version"]),
      do: raise("Checkpoint runtime version differs from the deployed runtime")

    started = Bench.now_ms()
    bundle = Path.join(session.directory, "restore-" <> Bench.id())
    runtime_id = "gsv-#{session.uid}-" <> Bench.id()
    session = save(session, phase: "Restoring", runtime_id: runtime_id, bundle: bundle)
    Bench.command("cp", ["-a", "--reflink=auto", Path.join(checkpoint, "bundle"), bundle])
    clone_ms = Bench.now_ms() - started

    Bench.runsc([
      "restore",
      "--bundle=#{bundle}",
      "--image-path=#{checkpoint}/memory",
      "--detach",
      "--background=false",
      runtime_id
    ])

    ready_ms = Bench.now_ms() - started
    guest(session, ["node", "-e", "require('fs').unlinkSync('/tmp/glossia/checkpoint-request')"])
    frame = frame(session, session.data["input_sequence"], completion["frame"]["sequence"])
    fresh_ms = Bench.now_ms() - started
    proof = probe(session)

    Bench.verify_continuity!(
      completion["proof"],
      proof,
      session.data["content"],
      completion["proof"]["page"]["clicks"]
    )

    after_processes = Bench.processes(runtime_id)

    if length(after_processes) < 2 or
         Enum.any?(completion["original_processes"], fn old ->
           Enum.any?(after_processes, &Bench.same_process?(old, &1))
         end),
       do: raise("Restoration did not replace the sandbox processes")

    save(session,
      phase: "Running",
      proof: proof,
      frame: frame,
      filesystem_clone_ms: clone_ms,
      runsc_restore_ms: ready_ms - clone_ms,
      runtime_ready_ms: ready_ms,
      fresh_frame_ms: fresh_ms,
      verified_ms: Bench.now_ms() - started
    )
  end

  defp settle_input(session) do
    if sequence = session.data["pending_sequence"], do: click(session, sequence), else: session
  end

  defp reconcile(session, resource) do
    metadata = resource["metadata"]
    finalizers = metadata["finalizers"] || []

    cond do
      metadata["deletionTimestamp"] ->
        stop(session)
        save(session, phase: "Deleted")

        request(:patch, collection() <> "/#{metadata["name"]}", %{
          "metadata" => %{
            "resourceVersion" => metadata["resourceVersion"],
            "finalizers" => List.delete(finalizers, @finalizer)
          }
        })

      @finalizer not in finalizers ->
        request(:patch, collection() <> "/#{metadata["name"]}", %{
          "metadata" => %{
            "resourceVersion" => metadata["resourceVersion"],
            "finalizers" => finalizers ++ [@finalizer]
          }
        })

      session.data["phase"] in ["Failed", "CleanupFailed", "CheckpointFailed"] ->
        publish(session, resource, "Failed", session.data["failure"])

      session.data["phase"] not in ["Empty", "Running", "Suspended"] ->
        raise(
          "Interrupted #{session.data["phase"]}: inspect journal; refusing cold restart or partial checkpoint"
        )

      session.data["phase"] == "Running" and Bench.processes(session.data["runtime_id"]) == [] ->
        reason = "Active sandbox was lost; refusing silent cold restart or rollback"
        save(session, phase: "Failed", failure: reason)
        raise(reason)

      get_in(resource, ["status", "phase"]) == resource["spec"]["desiredState"] and
          get_in(resource, ["status", "observedGeneration"]) == metadata["generation"] ->
        :ok

      true ->
        transition(session, resource)
    end
  end

  defp transition(session, resource) do
    desired = resource["spec"]["desiredState"]

    case {desired, session.data["phase"]} do
      {"Suspended", "Empty"} ->
        status(resource, %{"phase" => "Suspended", "reason" => "NotStarted"})

      _ ->
        session =
          case {desired, session.data["phase"]} do
            {"Running", "Empty"} -> create(session, resource["spec"]["title"])
            {"Running", "Suspended"} -> resume(session)
            {"Suspended", "Running"} -> suspend(session)
            _ -> session
          end

        session =
          if desired == "Running",
            do: click(session, resource["spec"]["inputSequence"] || 0),
            else: session

        phase =
          if desired == "Running" and
               session.data["input_sequence"] < session.data["requested_sequence"],
             do: "ApplyingInput",
             else: session.data["phase"]

        publish(session, resource, phase)
    end
  end

  defp publish(session, resource, phase, reason \\ nil) do
    status(resource, %{
      "phase" => phase,
      "reason" => reason,
      "evidence" => session.data,
      "runtimeProcesses" => Bench.processes(session.data["runtime_id"] || "not-created")
    })
  end

  defp reconcile_safely(resource) do
    try do
      reconcile(load(resource), resource)
    rescue
      error ->
        # Reload the durable journal: a failed operation may have persisted an
        # input intent or lifecycle transition before raising.
        try do
          recover(load(resource), error)
        rescue
          recovery -> IO.puts("Recovery deferred: #{Exception.message(recovery)}")
        end

        IO.puts(
          Jason.encode!(%{
            "session" => resource["metadata"]["name"],
            "error" => Exception.message(error)
          })
        )

        try do
          status(resource, %{
            "phase" => "Failed",
            "reason" => String.slice(Exception.message(error), -2000, 2000)
          })
        rescue
          conflict -> IO.puts("Status publication deferred: #{Exception.message(conflict)}")
        end
    end
  end

  defp recover(%{data: %{"phase" => "Quiescing"}} = session, error) do
    try do
      # Sample immediately before release, not the potentially stale journal.
      watermark = Bench.read_json(frame_path(session))["sequence"]

      guest(session, [
        "node",
        "-e",
        "require('fs').rmSync('/tmp/glossia/checkpoint-request',{force:true})"
      ])

      frame = frame(session, session.data["input_sequence"], watermark)
      proof = probe(session)

      Bench.verify_continuity!(
        session.data["proof"],
        proof,
        session.data["content"],
        session.data["proof"]["page"]["clicks"]
      )

      save(session, phase: "Running", proof: proof, frame: frame)
    rescue
      release ->
        save(session,
          phase: "CheckpointFailed",
          failure: Exception.message(error),
          release_error: Exception.message(release)
        )
    end
  end

  defp recover(%{data: %{"phase" => "Checkpointing"}} = session, error) do
    # This is authoritative live memory, not a disposable attempt. A failed
    # save may leave it alive; never force-delete it or roll back automatically.
    save(session, phase: "CheckpointFailed", failure: Exception.message(error))
  end

  defp recover(%{data: %{"phase" => phase}} = session, error)
       when phase in ["Starting", "Restoring"] do
    try do
      stop(session)
      save(session, phase: "Failed", failure: Exception.message(error))
    rescue
      cleanup ->
        save(session,
          phase: "CleanupFailed",
          failure: Exception.message(error),
          cleanup_error: Exception.message(cleanup)
        )
    end
  end

  defp recover(_session, _error), do: :ok
end
