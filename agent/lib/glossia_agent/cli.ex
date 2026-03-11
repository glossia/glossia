defmodule GlossiaAgent.CLI do
  @moduledoc """
  CLI entry point for the standalone Burrito binary.

  Reads configuration from a JSON file (uploaded by the sandbox orchestrator),
  clones the target repository, connects to the Phoenix server via WebSocket,
  and runs the appropriate workflow (setup or translate).
  """

  require Logger

  @doc """
  Main entry point. Called when the Burrito binary starts.

  Expects command-line arguments:
    --server-url=URL   Phoenix server URL
    --token=TOKEN      Signed session token
    --project-id=ID    Project UUID
    --config-path=PATH Path to the config JSON file
  """
  def main(args \\ System.argv()) do
    opts = parse_args(args)
    config = read_config(opts.config_path)
    mode = config["mode"] || "setup"

    Logger.info("Starting agent in #{mode} mode for project #{opts.project_id}")

    topic = build_topic(mode, config)

    emitter =
      GlossiaAgent.Events.ChannelEmitter.new(
        server_url: opts.server_url,
        token: opts.token,
        topic: topic
      )

    repo_path = config["repo_path"] || "/home/user/repo"

    case clone_repo(config, repo_path) do
      :ok ->
        run_workflow(mode, config, repo_path, emitter)

      {:error, reason} ->
        Logger.error("Failed to clone repository: #{inspect(reason)}")

        GlossiaAgent.Events.Emitter.fail(
          emitter,
          "Failed to clone repository: #{inspect(reason)}"
        )

        System.halt(1)
    end
  rescue
    error ->
      Logger.error("Agent crashed: #{Exception.message(error)}")
      System.halt(1)
  end

  defp parse_args(args) do
    {parsed, _, _} =
      OptionParser.parse(args,
        strict: [
          server_url: :string,
          token: :string,
          project_id: :string,
          config_path: :string
        ],
        aliases: []
      )

    %{
      server_url: Keyword.fetch!(parsed, :server_url),
      token: Keyword.fetch!(parsed, :token),
      project_id: Keyword.fetch!(parsed, :project_id),
      config_path: Keyword.fetch!(parsed, :config_path)
    }
  end

  defp read_config(path) do
    path
    |> File.read!()
    |> Jason.decode!()
  end

  defp build_topic("translate", config) do
    translation_id =
      config["translation_id"] || raise "translation_id required for translate mode"

    "agent:translate:#{translation_id}"
  end

  defp build_topic(_mode, config) do
    project_id = config["project_id"] || raise "project_id required in config"
    "agent:setup:#{project_id}"
  end

  defp clone_repo(config, repo_path) do
    full_name = config["github_repo_full_name"]
    token = config["github_token"]
    default_branch = config["github_repo_default_branch"] || "main"

    if is_nil(full_name) || full_name == "" do
      Logger.info("No github_repo_full_name in config, skipping clone")
      :ok
    else
      clone_url =
        if token && token != "" do
          "https://x-access-token:#{token}@github.com/#{full_name}.git"
        else
          "https://github.com/#{full_name}.git"
        end

      if File.dir?(Path.join(repo_path, ".git")) do
        Logger.info("Repository already cloned at #{repo_path}, fetching latest")
        run_cmd("git", ["-C", repo_path, "fetch", "origin", default_branch])
        run_cmd("git", ["-C", repo_path, "reset", "--hard", "origin/#{default_branch}"])
      else
        File.mkdir_p!(Path.dirname(repo_path))

        run_cmd("git", ["clone", "--depth", "1", "--branch", default_branch, clone_url, repo_path])
      end
    end
  end

  defp run_cmd(cmd, args) do
    case System.cmd(cmd, args, stderr_to_stdout: true) do
      {_output, 0} ->
        :ok

      {output, code} ->
        {:error, "#{cmd} exited with code #{code}: #{String.slice(output, 0, 500)}"}
    end
  end

  defp run_workflow("translate", config, repo_path, emitter) do
    minimax_api_key = config["minimax_api_key"] || ""
    model = config["model"] || "MiniMax-M2.5"

    case GlossiaAgent.translate(
           repo_path: repo_path,
           minimax_api_key: minimax_api_key,
           model: model,
           emitter: emitter
         ) do
      :ok ->
        Logger.info("Translation workflow completed successfully")
        System.halt(0)

      {:error, reason} ->
        Logger.error("Translation workflow failed: #{inspect(reason)}")
        System.halt(1)
    end
  end

  defp run_workflow(_mode, config, repo_path, emitter) do
    minimax_api_key = config["minimax_api_key"] || ""
    model = config["model"] || "MiniMax-M2.5"
    target_languages = config["target_languages"] || []

    case GlossiaAgent.setup(
           directory: repo_path,
           minimax_api_key: minimax_api_key,
           model: model,
           target_languages: target_languages,
           emitter: emitter
         ) do
      {:ok, _content} ->
        Logger.info("Setup workflow completed successfully")
        System.halt(0)

      {:error, reason} ->
        Logger.error("Setup workflow failed: #{inspect(reason)}")
        System.halt(1)
    end
  end
end
