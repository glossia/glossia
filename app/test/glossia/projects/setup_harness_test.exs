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

          String.starts_with?(command, "mkdir -p") or String.starts_with?(command, "chmod 600") ->
            ok_result()
        end
      end
    }

    assert :ok =
             SetupHarness.run(callbacks, self(),
               repo_path: "/workspace/repo",
               repository: %{
                 full_name: "glossia/demo",
                 default_branch: "main",
                 token: nil,
                 clone_url: "file:///mnt/remotes/glossia/demo"
               },
               target_languages: ["es", "fr"],
               harness: %{
                 command: "opencode",
                 opencode_config: %{"model" => "openai/gpt-5.4"},
                 opencode_auth: %{"openai" => %{"type" => "oauth", "access" => "token"}}
               }
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

    assert_received {:shell_command, clone_command, _opts}
    assert clone_command =~ "file:///mnt/remotes/glossia/demo"

    auth_path = "/workspace/.glossia-harness/.local/share/opencode/auth.json"

    assert %{"openai" => %{"type" => "oauth", "access" => "token"}} =
             files |> Agent.get(&Map.fetch!(&1, auth_path)) |> JSON.decode!()
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

  test "runs Codex with its isolated session and maps progress events" do
    {:ok, files} = Agent.start_link(fn -> %{} end)

    callbacks = %{
      upload_file: fn path, content ->
        Agent.update(files, &Map.put(&1, path, content))
        :ok
      end,
      download_file: fn path -> {:ok, Agent.get(files, &Map.get(&1, path, ""))} end,
      execute_shell: fn command, opts ->
        codex_command? = String.contains?(command, "codex") and String.contains?(command, "exec")

        if codex_command?,
          do: send(self(), {:codex_invocation, command, opts})

        cond do
          String.contains?(command, "git clone") -> ok_result()
          codex_command? -> ok_result()
          String.contains?(command, "git status") -> ok_result("?? GLOSSIA.md\n")
          String.starts_with?(command, "mkdir -p") -> ok_result()
          String.starts_with?(command, "chmod 600") -> ok_result()
        end
      end
    }

    auth = %{
      "auth_mode" => "chatgpt",
      "tokens" => %{
        "access_token" => "access",
        "refresh_token" => "refresh",
        "account_id" => "account"
      }
    }

    assert :ok =
             SetupHarness.run(callbacks, self(),
               repo_path: "/workspace/repo",
               repository: %{
                 full_name: "glossia/demo",
                 default_branch: "main",
                 clone_url: "file:///mnt/remotes/glossia/demo"
               },
               target_languages: ["es"],
               harness: %{
                 name: "codex",
                 command: "codex",
                 model: "gpt-5.4",
                 codex_auth: auth,
                 context: "Use account terminology."
               }
             )

    assert auth ==
             files
             |> Agent.get(&Map.fetch!(&1, "/workspace/.glossia-harness/.codex/auth.json"))
             |> JSON.decode!()

    assert_received {:codex_invocation, command, opts}
    assert command =~ "codex"
    assert command =~ "exec"
    assert command =~ "--dangerously-bypass-approvals-and-sandbox"
    assert command =~ "Additional account context"
    assert opts[:env]["CODEX_HOME"] == "/workspace/.glossia-harness/.codex"

    assert %{"event_type" => "text", "content" => "ready"} =
             SetupHarness.harness_event(
               ~s({"type":"item.completed","item":{"type":"agent_message","text":"ready"}})
             )
  end

  test "runs Claude Code with its isolated session and maps progress events" do
    {:ok, files} = Agent.start_link(fn -> %{} end)

    callbacks = %{
      upload_file: fn path, content ->
        Agent.update(files, &Map.put(&1, path, content))
        :ok
      end,
      download_file: fn path -> {:ok, Agent.get(files, &Map.get(&1, path, ""))} end,
      execute_shell: fn command, opts ->
        claude_command? =
          String.contains?(command, "claude") and String.contains?(command, "--print")

        if claude_command?, do: send(self(), {:claude_invocation, command, opts})

        cond do
          String.contains?(command, "git clone") -> ok_result()
          claude_command? -> ok_result()
          String.contains?(command, "git status") -> ok_result("?? GLOSSIA.md\n")
          String.starts_with?(command, "mkdir -p") -> ok_result()
          String.starts_with?(command, "chmod 600") -> ok_result()
        end
      end
    }

    auth = %{
      "claudeAiOauth" => %{
        "accessToken" => "access",
        "refreshToken" => "refresh",
        "expiresAt" => System.system_time(:millisecond) + 60_000
      }
    }

    assert :ok =
             SetupHarness.run(callbacks, self(),
               repo_path: "/workspace/repo",
               repository: %{
                 full_name: "glossia/demo",
                 default_branch: "main",
                 clone_url: "file:///mnt/remotes/glossia/demo"
               },
               target_languages: ["es"],
               harness: %{
                 name: "claude",
                 command: "claude",
                 model: "claude-sonnet-4-6",
                 claude_auth: auth,
                 context: "Use account terminology."
               }
             )

    assert auth ==
             files
             |> Agent.get(
               &Map.fetch!(&1, "/workspace/.glossia-harness/.claude/.credentials.json")
             )
             |> JSON.decode!()

    assert_received {:claude_invocation, command, opts}
    assert command =~ "--output-format"
    assert command =~ "stream-json"
    assert command =~ "--safe-mode"
    assert command =~ "--dangerously-skip-permissions"
    assert command =~ "Additional account context"
    assert opts[:env]["HOME"] == "/workspace/.glossia-harness"

    assert [
             %{"event_type" => "text", "content" => "Inspecting"},
             %{"event_type" => "tool_call", "metadata" => %{"tool_name" => "Read"}}
           ] =
             SetupHarness.harness_event(
               ~s({"type":"assistant","message":{"content":[{"type":"text","text":"Inspecting"},{"type":"tool_use","name":"Read","input":{"file_path":"README.md"}}]}})
             )

    assert [%{"event_type" => "tool_result", "content" => "done"}] =
             SetupHarness.harness_event(
               ~s({"type":"user","message":{"content":[{"type":"tool_result","content":"done","is_error":false}]}})
             )
  end

  defp ok_result(stdout \\ "") do
    {:ok, %{"exitCode" => 0, "stdout" => stdout, "stderr" => "", "timedOut" => false}}
  end
end
