defmodule Glossia.Toki.HostHarness do
  @moduledoc """
  Explicit development-only host inference through Condukt's Claude adapter.

  The CLI runs synchronously in the reply worker, not a detached Condukt
  session. A separate monitor owns the disposable home/cwd so even an untrappable
  worker exit removes CLI state. This is tool-less CLI configuration, not an OS
  security sandbox: the installed executable and machine policy must be trusted.
  """

  alias Condukt.AgentRuntimes.Claude
  alias Glossia.Translations.Credentials

  @safe_env ~w(PATH LANG LC_ALL LC_CTYPE TZ)

  # Called only by server runtime configuration, never with request parameters.
  def config(environment, env) do
    case {environment, env["GLOSSIA_TOKI_HARNESS"]} do
      {:dev, "claude"} ->
        [harness: :claude, model: env["GLOSSIA_TOKI_HARNESS_MODEL"]]

      {:dev, harness} when harness not in [nil, ""] ->
        raise "GLOSSIA_TOKI_HARNESS supports only claude (Codex is not tool-less; Pi has no Condukt adapter)"

      _ ->
        []
    end
  end

  def reply(system_prompt, transcript, config) do
    with :claude <- config[:harness],
         command when is_binary(command) <- System.find_executable("claude"),
         token when is_binary(token) and token != "" <- oauth_token() do
      with_workspace(fn cwd ->
        wrapper = Path.join(cwd, "claude")

        # MuonTrap without Linux cgroups kills only its immediate child. Keep
        # a shell parent with a dedicated CLI job group and kill that whole
        # group on every exit, including TERM on timeout/worker death.
        File.write!(wrapper, """
        #!/bin/bash
        set -m
        trap 'kill -KILL -- "-$!" 2>/dev/null || true' EXIT
        trap 'exit 143' TERM HUP INT
        "$GLOSSIA_TOKI_CLAUDE_COMMAND" --version > "$HOME/version" &
        wait "$!" || exit $?
        IFS=' .' read -r major minor patch rest < "$HOME/version"
        if ! [[ "$major" =~ ^[0-9]+$ && "$minor" =~ ^[0-9]+$ && "$patch" =~ ^[0-9]+$ ]] ||
           ! (( major > 2 || (major == 2 && minor > 1) || (major == 2 && minor == 1 && patch >= 285) )); then
          printf 'Toki requires Claude Code 2.1.285 or later for disabled API retries\\n' >&2
          exit 78
        fi
        "$GLOSSIA_TOKI_CLAUDE_COMMAND" "$@" < /dev/null &
        wait "$!"
        """)

        File.chmod!(wrapper, 0o700)

        context = %{
          cwd: cwd,
          system_prompt: system_prompt,
          secrets: %Condukt.Secrets{env: [{"CLAUDE_CODE_OAUTH_TOKEN", token}]},
          runtime_opts: [
            command: wrapper,
            model: config[:model],
            permission_mode: "dontAsk",
            timeout: 60_000,
            env: environment(cwd, command),
            extra_args: [
              "--tools",
              "",
              "--safe-mode",
              "--disable-slash-commands",
              "--strict-mcp-config",
              "--mcp-config",
              ~s({"mcpServers":{}}),
              "--setting-sources",
              "",
              "--settings",
              ~s({"disableAllHooks":true}),
              "--max-turns",
              "1",
              "--"
            ]
          ]
        }

        Claude.run(transcript, context, timeout: 65_000)
      end)
    else
      _ -> {:error, :provider_unavailable}
    end
  end

  defp oauth_token do
    case System.get_env("CLAUDE_CODE_OAUTH_TOKEN") do
      token when is_binary(token) and token != "" -> token
      _ -> local_token()
    end
  end

  defp local_token do
    case Credentials.claude_session() do
      %{auth: {:oauth, token}} -> token
      _ -> nil
    end
  end

  defp environment(cwd, command) do
    # Condukt overlays env rather than clearing it, and converts nil to "".
    # Explicitly blank everything except the small CLI bootstrap allowlist.
    # In particular, do not inherit server secrets, NODE_OPTIONS, BASH_ENV,
    # CLI settings, provider routing, or a real HOME with hooks/plugins.
    System.get_env()
    |> Map.new(fn {key, value} -> {key, if(key in @safe_env, do: value, else: "")} end)
    |> Map.merge(%{
      "GLOSSIA_TOKI_CLAUDE_COMMAND" => command,
      "HOME" => cwd,
      "CLAUDE_CONFIG_DIR" => cwd,
      "XDG_CONFIG_HOME" => cwd,
      "TMPDIR" => cwd <> "/",
      "TMP" => cwd,
      "TEMP" => cwd,
      "CLAUDE_CODE_MAX_RETRIES" => "0",
      "CLAUDE_CODE_NONSTREAMING_TIMEOUT_RETRIES" => "0",
      "CLAUDE_CODE_RETRY_WATCHDOG" => "0",
      "CLAUDE_CODE_MAX_OUTPUT_TOKENS" => "2048",
      "CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC" => "1",
      "DISABLE_AUTOUPDATER" => "1"
    })
    |> Map.to_list()
  end

  defp with_workspace(run) do
    owner = self()

    cwd =
      Path.join(
        System.tmp_dir!(),
        "glossia-toki-#{Base.url_encode64(:crypto.strong_rand_bytes(18))}"
      )

    {cleaner, monitor} =
      spawn_monitor(fn ->
        owner_monitor = Process.monitor(owner)
        File.mkdir!(cwd)
        File.chmod!(cwd, 0o700)
        send(owner, {:workspace_ready, self()})

        receive do
          {:cleanup, ^owner} -> :ok
          {:DOWN, ^owner_monitor, :process, ^owner, _reason} -> :ok
        end

        # MuonTrap closes its port on timeout/owner death. Give the wrapper's
        # exit trap and MuonTrap's 500 ms grace time to finish before deletion.
        Process.sleep(750)
        File.rm_rf!(cwd)
      end)

    receive do
      {:workspace_ready, ^cleaner} ->
        try do
          run.(cwd)
        after
          send(cleaner, {:cleanup, owner})

          receive do
            {:DOWN, ^monitor, :process, ^cleaner, _reason} -> :ok
          end
        end

      {:DOWN, ^monitor, :process, ^cleaner, _reason} ->
        {:error, :provider_unavailable}
    end
  end
end
