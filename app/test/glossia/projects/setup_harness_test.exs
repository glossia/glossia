defmodule Glossia.Projects.SetupHarnessTest do
  use ExUnit.Case, async: true

  alias Glossia.Projects.SetupHarness

  test "runs setup orchestration in Elixir and writes a changed-file manifest" do
    {:ok, files} = Agent.start_link(fn -> %{} end)

    callbacks = %{
      upload_file: fn path, content ->
        Agent.update(files, &Map.put(&1, path, content))
        :ok
      end,
      download_file: fn path ->
        {:ok, Agent.get(files, &Map.get(&1, path, ""))}
      end,
      execute_shell: fn command, opts ->
        send(self(), {:shell_command, command, opts})

        cond do
          String.contains?(command, "git clone") ->
            ok_result()

          String.contains?(command, "opencode") ->
            ok_result()

          String.contains?(command, "git status") ->
            ok_result("""
            ?? GLOSSIA.md
             M src/i18n/en.json
            ?? .glossia/docs/guide.md/es.lock
            """)

          String.starts_with?(command, "mkdir -p") ->
            ok_result()
        end
      end
    }

    assert :ok =
             SetupHarness.run(callbacks, self(),
               repo_path: "/workspace/repo",
               repository: %{full_name: "glossia/demo", default_branch: "main", token: nil},
               target_languages: ["es", "fr"],
               harness: %{command: "opencode"}
             )

    manifest_path = "/workspace/#{SetupHarness.change_manifest_filename()}"
    manifest = Agent.get(files, &Map.fetch!(&1, manifest_path))

    assert %{
             "version" => 1,
             "files" => [
               %{"path" => "GLOSSIA.md", "status" => "added"},
               %{"path" => "src/i18n/en.json", "status" => "modified"}
             ]
           } = JSON.decode!(manifest)

    assert_received {:agent_event, %{"event_type" => "prompt", "content" => prompt}}
    assert prompt =~ "Use exactly these target languages: es, fr."
    assert prompt =~ "source_language: en"
    assert prompt =~ ~s("docs/**/*.md": "docs/i18n/{locale}/{relpath}")
    assert prompt =~ "Locale-specific context belongs in GLOSSIA/<locale>.md."
    assert prompt =~ "Do not create translation lockfiles during setup."
    assert_received {:agent_event, %{"event_type" => "completed"}}
  end

  test "maps OpenCode JSON lines into setup events" do
    assert %{"event_type" => "text", "content" => "Working"} =
             SetupHarness.open_code_event(~s({"type":"text","part":{"text":"Working"}}))

    assert [
             %{"event_type" => "tool_call", "metadata" => %{"tool_name" => "edit"}},
             %{"event_type" => "tool_result", "content" => "done"}
           ] =
             SetupHarness.open_code_event(
               ~s({"type":"tool_use","part":{"tool":"edit","state":{"status":"completed","output":"done"}}})
             )
  end

  defp ok_result(stdout \\ "") do
    {:ok, %{"exitCode" => 0, "stdout" => stdout, "stderr" => "", "timedOut" => false}}
  end
end
