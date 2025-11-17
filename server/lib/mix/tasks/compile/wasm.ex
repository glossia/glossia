defmodule Mix.Tasks.Compile.Wasm do
  @moduledoc """
  Compiles Wasm format handlers from Zig source files.

  This compiler task automatically builds Wasm modules when:
  - Source files are newer than compiled .wasm files
  - .wasm files are missing
  - Force compilation is requested

  Runs lazily - only compiles when needed.
  """

  use Mix.Task.Compiler

  @recursive true
  @wasm_dir "priv/wasm"
  @handlers_dir Path.join(@wasm_dir, "handlers")
  @build_dir Path.join(@wasm_dir, "zig-out/build")

  @impl Mix.Task.Compiler
  def run(_args) do
    # Ensure build directory exists
    File.mkdir_p!(@build_dir)

    case check_zig_installed() do
      :ok ->
        compile_handlers()

      {:error, reason} ->
        Mix.shell().error(reason)
        Mix.shell().info("Install Zig: mise install")
        {:error, []}
    end
  end

  @impl Mix.Task.Compiler
  def manifests, do: [manifest_path()]

  @impl Mix.Task.Compiler
  def clean do
    if File.exists?(@build_dir) do
      @build_dir
      |> File.ls!()
      |> Enum.filter(&String.ends_with?(&1, ".wasm"))
      |> Enum.each(&File.rm!(Path.join(@build_dir, &1)))
    end

    if File.exists?(manifest_path()) do
      File.rm!(manifest_path())
    end

    :ok
  end

  defp manifest_path do
    Path.join(Mix.Project.manifest_path(), "compile.wasm")
  end

  defp check_zig_installed do
    case System.cmd("mise", ["exec", "--", "zig", "version"], stderr_to_stdout: true) do
      {version, 0} ->
        Mix.shell().info("Using Zig #{String.trim(version)}")
        :ok

      _ ->
        {:error, "Zig is not installed or not available via Mise"}
    end
  end

  defp compile_handlers do
    # Find all .zig files in handlers directory
    handler_files =
      if File.exists?(@handlers_dir) do
        @handlers_dir
        |> File.ls!()
        |> Enum.filter(&String.ends_with?(&1, ".zig"))
      else
        []
      end

    if Enum.empty?(handler_files) do
      Mix.shell().info("No Wasm handlers to compile")
      {:noop, []}
    else
      # Check which handlers need recompilation
      stale_handlers =
        Enum.filter(handler_files, fn file ->
          source_path = Path.join(@handlers_dir, file)
          output_name = Path.basename(file, ".zig") <> ".wasm"
          output_path = Path.join(@build_dir, output_name)

          needs_compilation?(source_path, output_path)
        end)

      if Enum.empty?(stale_handlers) do
        Mix.shell().info("Wasm handlers are up to date")
        {:noop, []}
      else
        Mix.shell().info("Compiling #{length(stale_handlers)} Wasm handler(s)...")

        # Use zig build for compilation
        case System.cmd(
               "mise",
               ["exec", "--", "zig", "build"],
               cd: @wasm_dir,
               stderr_to_stdout: true
             ) do
          {_output, 0} ->
            Mix.shell().info("Successfully compiled Wasm handlers")

            # Print file sizes
            print_handler_sizes()

            # Update manifest
            write_manifest(handler_files)

            {:ok, []}

          {output, _} ->
            Mix.shell().error("Failed to compile Wasm handlers:")
            Mix.shell().error(output)
            {:error, []}
        end
      end
    end
  end

  defp needs_compilation?(source_path, output_path) do
    cond do
      not File.exists?(output_path) ->
        true

      not File.exists?(source_path) ->
        false

      true ->
        source_mtime = File.stat!(source_path).mtime
        output_mtime = File.stat!(output_path).mtime
        source_mtime > output_mtime
    end
  end

  defp print_handler_sizes do
    if File.exists?(@build_dir) do
      @build_dir
      |> File.ls!()
      |> Enum.filter(&String.ends_with?(&1, ".wasm"))
      |> Enum.each(fn file ->
        path = Path.join(@build_dir, file)
        size_bytes = File.stat!(path).size
        size_kb = Float.round(size_bytes / 1024, 1)
        Mix.shell().info("  #{file}: #{size_kb} KB")
      end)
    end
  end

  defp write_manifest(files) do
    manifest = %{
      compiled_at: DateTime.utc_now() |> DateTime.to_string(),
      files: files
    }

    manifest_path()
    |> Path.dirname()
    |> File.mkdir_p!()

    File.write!(manifest_path(), :erlang.term_to_binary(manifest))
  end
end
