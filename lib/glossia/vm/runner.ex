defmodule Glossia.Vm.Runner do
  require Logger

  @timeout 60 * 3

  def run() do
  end

  def run_remotely() do
  end

  def run_locally!() do
    # Ensures that the default handlers work with the software running in the VM
    # The port in which the application runs in development.
    arguments =
      ["/usr/bin/env", "docker", "run"] ++
        ["--init"] ++
        ["--volume", runner_directory() <> ":" <> "/runner"] ++
        ["--workdir", "/runner"] ++
        ["--publish", "4000:4000"] ++
        ["--env", "GLOSSIA_URL=" <> "http://127.0.0.1:4000"] ++
        ["denoland/deno:" <> Application.get_env(:glossia, :versions)[:deno]] ++
        default_deno_arguments() ++
        ["./index.ts"]

    Logger.debug("Running: " <> (arguments |> Enum.join(" ")))
    Exile.stream!(arguments, exit_timeout: @timeout) |> Stream.run()
  end

  def default_deno_arguments do
    ["run"] ++
      ["--allow-env=GLOSSIA_URL"] ++
      ["--allow-net"]
  end

  def runner_directory() do
    app_dir = Application.app_dir(:glossia)
    Path.join([app_dir, "priv", "static", "runner"])
  end

  def docker_available?() do
    case Exile.stream(["/usr/bin/env", "which", "docker"]) |> Enum.to_list() do
      [_, {:exit, {:status, 0}}] -> true
      _ -> false
    end
  end
end
