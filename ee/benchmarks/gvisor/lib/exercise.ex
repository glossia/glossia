defmodule Glossia.SandboxBench.Exercise do
  @moduledoc "Exercises the deployed fixed benchmark through its Kubernetes CR interface."

  alias Glossia.SandboxBench, as: Bench

  @namespace "glossia-sandbox-bench"
  @sessions ["session-a", "session-b"]

  def main(args) do
    {opts, rest, invalid} =
      OptionParser.parse(args, strict: [output: :string, cycles: :integer, idle_seconds: :float])

    output = opts[:output]
    cycles = Keyword.get(opts, :cycles, 3)
    idle_seconds = Keyword.get(opts, :idle_seconds, 3)

    unless invalid == [] and rest == [] and is_binary(output) and cycles in 1..3 and
             idle_seconds >= 0 do
      raise ArgumentError,
            "Usage: mix run exercise.exs --output PATH --cycles 3 --idle-seconds 3 (cycles 1..3, idle duration nonnegative)"
    end

    context = kubectl(["config", "view", "--minify", "-o", "json"]) |> Jason.decode!()
    server = context |> Map.fetch!("clusters") |> hd() |> get_in(["cluster", "server"])

    unless URI.parse(server).host in ["127.0.0.1", "localhost", "::1"] do
      raise "Run only on the disposable local k3s host, never a shared cluster"
    end

    File.mkdir_p!(Path.dirname(output))
    :ok = File.mkdir(output)
    result_path = Path.join(output, "result.json")

    Bench.write_json(result_path, %{
      "success" => false,
      "cycles" => cycles,
      "idle_seconds" => idle_seconds,
      "samples" => []
    })

    try do
      run(output, result_path, cycles, idle_seconds)
    after
      File.write!(
        Path.join(output, "controller.log"),
        kubectl(["logs", "gvisor-reconciler-0", "--tail=100"])
      )
    end

    result = Bench.read_json(result_path)
    IO.puts(Jason.encode!(result, pretty: true))
    result
  end

  defp run(output, result_path, cycles, idle_seconds) do
    current = wait_all("Running")

    for key <- ["server_nonce", "browser_nonce"] do
      [first, second] =
        Enum.map(@sessions, &get_in(evidence(current[&1]), ["proof", "page", key]))

      if first == second, do: raise("The two sandboxes share memory identities")
    end

    capture(output, "initial", current)
    click_all(current)
    current = wait_all("Running")
    capture(output, "clicked", current)

    Enum.reduce(0..(cycles - 1), current, fn cycle, current ->
      set_state("Suspended")
      stopped = wait_all("Suspended")
      verify_absence!(stopped)
      capture(output, "cycle-#{cycle}-suspended", stopped)
      Process.sleep(round(idle_seconds * 1000))

      stopped =
        if cycle == 0 do
          # Only the PVC generation may survive: replace the outer runner too.
          kubectl(["delete", "pod", "gvisor-reconciler-0", "--wait=true", "--timeout=60s"])

          kubectl([
            "rollout",
            "status",
            "statefulset/gvisor-reconciler",
            "--timeout=90s"
          ])

          wait_all("Suspended")
        else
          stopped
        end

      requested = Bench.now_ms()
      set_state("Running")
      restored = wait_all("Running")
      acknowledged_ms = Bench.now_ms() - requested

      for name <- @sessions do
        before = evidence(current[name])
        after_restore = evidence(restored[name])
        suspended = evidence(stopped[name])

        Bench.verify_continuity!(
          before["proof"],
          after_restore["proof"],
          before["content"],
          before["proof"]["page"]["clicks"]
        )

        resumed_sequence = get_in(after_restore, ["frame", "sequence"])
        stopped_sequence = get_in(suspended, ["frame", "sequence"])

        unless is_integer(resumed_sequence) and is_integer(stopped_sequence) and
                 resumed_sequence > stopped_sequence do
          raise "Resume used a frame captured before checkpoint"
        end

        if Enum.any?(suspended["original_processes"], fn old ->
             Enum.any?(
               restored[name]["status"]["runtimeProcesses"],
               &Bench.same_process?(old, &1)
             )
           end) do
          raise "Original sandbox process survived"
        end

        sample =
          Map.new(
            [
              "filesystem_clone_ms",
              "runsc_restore_ms",
              "runtime_ready_ms",
              "fresh_frame_ms",
              "verified_ms"
            ],
            &{&1, Map.fetch!(after_restore, &1)}
          )
          |> Map.merge(%{
            "cycle" => cycle,
            "session" => name,
            "both_sessions_acknowledged_ms" => acknowledged_ms,
            "released_rss_kib" =>
              Enum.sum(Enum.map(suspended["original_processes"], & &1["rss_kib"]))
          })

        # Persist every accepted sample even if a later check fails.
        result = Bench.read_json(result_path)
        Bench.write_json(result_path, Map.update!(result, "samples", &(&1 ++ [sample])))
      end

      capture(output, "cycle-#{cycle}-restored", restored)
      requested = Bench.now_ms()
      click_all(restored)
      current = wait_all("Running")
      interactive_ms = Bench.now_ms() - requested

      for name <- @sessions do
        before = evidence(restored[name])
        after_click = evidence(current[name])

        Bench.verify_continuity!(
          before["proof"],
          after_click["proof"],
          before["content"],
          before["proof"]["page"]["clicks"] + 1
        )

        result = Bench.read_json(result_path)

        samples =
          Enum.map(result["samples"], fn sample ->
            if sample["cycle"] == cycle and sample["session"] == name,
              do: Map.put(sample, "post_resume_both_clicks_ms", interactive_ms),
              else: sample
          end)

        Bench.write_json(result_path, Map.put(result, "samples", samples))
      end

      capture(output, "cycle-#{cycle}-interactive", current)
      current
    end)

    set_state("Suspended")
    capture(output, "final-suspended", wait_all("Suspended"))
    result = Bench.read_json(result_path)

    Bench.write_json(
      result_path,
      Map.merge(result, %{
        "success" => true,
        "median_fresh_frame_ms" => median(result["samples"], "fresh_frame_ms"),
        "median_runtime_ready_ms" => median(result["samples"], "runtime_ready_ms")
      })
    )
  end

  defp verify_absence!(stopped) do
    for name <- @sessions do
      unless stopped[name]["status"]["runtimeProcesses"] == [] do
        raise "Suspension retained sandbox processes"
      end

      runtime_id = evidence(stopped[name])["runtime_id"]
      check = "IO.puts(Jason.encode!(Glossia.SandboxBench.processes(#{inspect(runtime_id)})))"

      observed =
        kubectl([
          "exec",
          "gvisor-reconciler-0",
          "--",
          "mix",
          "run",
          "--no-start",
          "-e",
          check
        ])
        |> Jason.decode!()

      unless observed == [] do
        raise "Independent host inspection found suspended sandbox processes"
      end
    end
  end

  defp capture(output, label, values) do
    Bench.write_json(Path.join(output, "#{label}.json"), values)

    for {name, value} <- values do
      uid = value["metadata"]["uid"]
      image = kubectl(["exec", "gvisor-reconciler-0", "--", "cat", "/state/#{uid}/latest.jpg"])

      unless match?(<<0xFF, 0xD8, _::binary>>, image) do
        raise "Captured artifact is not JPEG"
      end

      File.write!(Path.join(output, "#{label}-#{name}.jpg"), image)
    end
  end

  defp wait_all(phase), do: Map.new(@sessions, &{&1, wait(&1, phase)})

  defp wait(name, phase) do
    Bench.await(
      fn ->
        value = kubectl(["get", "sandboxsession", name, "-o", "json"]) |> Jason.decode!()
        status = Map.get(value, "status", %{})

        if status["observedGeneration"] == value["metadata"]["generation"] do
          if status["phase"] == "Failed", do: raise("#{name}: #{inspect(status)}")
          if status["phase"] == phase, do: value
        end
      end,
      "#{name} did not reach #{phase}",
      180_000
    )
  end

  defp click_all(current) do
    for name <- @sessions do
      patch(name, %{"inputSequence" => current[name]["spec"]["inputSequence"] + 1})
    end
  end

  defp set_state(state) do
    for name <- @sessions, do: patch(name, %{"desiredState" => state})
  end

  defp patch(name, spec) do
    kubectl([
      "patch",
      "sandboxsession",
      name,
      "--type=merge",
      "-p",
      Jason.encode!(%{"spec" => spec})
    ])
  end

  defp evidence(value), do: value["status"]["evidence"]

  defp kubectl(args) do
    Bench.command("k3s", ["kubectl", "-n", @namespace | args], timeout: 120_000)
  end

  defp median(samples, key) do
    values = samples |> Enum.map(&Map.fetch!(&1, key)) |> Enum.sort()
    middle = div(length(values), 2)
    (Enum.at(values, middle - 1) + Enum.at(values, middle)) / 2
  end
end
