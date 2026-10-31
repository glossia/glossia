defmodule Glossia.SandboxBench do
  @moduledoc "Shared command, persistence and continuity checks for the opt-in benchmark."

  def command(executable, args, opts \\ []) do
    directory = Path.join(System.tmp_dir!(), "glossia-command-" <> id())
    File.mkdir!(directory)
    File.chmod!(directory, 0o700)
    stdout = Path.join(directory, "stdout")
    stderr = Path.join(directory, "stderr")

    try do
      # Detached runsc children retain stdio. Files avoid waiting on their pipe
      # EOF; MuonTrap still bounds and supervises the launching command.
      {_, status} =
        MuonTrap.cmd(
          "/bin/sh",
          [
            "-c",
            ~S(exec "$@" > "$GLOSSIA_CMD_OUT" 2> "$GLOSSIA_CMD_ERR"),
            "bench",
            executable | args
          ],
          env: [{"GLOSSIA_CMD_OUT", stdout}, {"GLOSSIA_CMD_ERR", stderr}],
          into: "",
          timeout: Keyword.get(opts, :timeout, 120_000)
        )

      output = if File.exists?(stdout), do: File.read!(stdout), else: ""
      error = if File.exists?(stderr), do: File.read!(stderr), else: ""

      if status != 0,
        do:
          raise("#{executable} failed (#{inspect(status)}): #{String.slice(error, -3000, 3000)}")

      output
    after
      File.rm_rf!(directory)
    end
  end

  def runsc(args, opts \\ []) do
    command(
      "runsc",
      [
        "--root=/run/bench-runsc",
        "--platform=systrap",
        "--network=none",
        "--overlay2=none",
        "--ignore-cgroups=true" | args
      ],
      opts
    )
  end

  def read_json(path), do: path |> File.read!() |> Jason.decode!()

  def write_json(path, value) do
    temporary = path <> ".next"
    {:ok, file} = :file.open(String.to_charlist(temporary), [:write, :binary, :raw])

    try do
      :ok = :file.write(file, Jason.encode!(value))
      :ok = :file.sync(file)
    after
      :file.close(file)
    end

    File.rename!(temporary, path)

    {:ok, directory} =
      :file.open(String.to_charlist(Path.dirname(path)), [:read, :raw, :directory])

    try do
      :ok = :file.sync(directory)
    after
      :file.close(directory)
    end

    value
  end

  def processes(runtime_id) do
    Path.wildcard("/proc/[0-9]*")
    |> Enum.flat_map(fn directory ->
      with {:ok, cmdline} <- File.read(Path.join(directory, "cmdline")),
           argv = :binary.split(cmdline, <<0>>, [:global]),
           true <- runtime_id in argv and ("boot" in argv or "gofer" in argv),
           {:ok, stat} <- File.read(Path.join(directory, "stat")),
           fields = stat |> String.split(")") |> List.last() |> String.split(),
           false <- hd(fields) == "Z",
           {:ok, status} <- File.read(Path.join(directory, "status")),
           [_, rss] <- Regex.run(~r/^VmRSS:\s+(\d+)/m, status) do
        [
          %{
            "pid" => directory |> Path.basename() |> String.to_integer(),
            "start" => fields |> Enum.at(19) |> String.to_integer(),
            "rss_kib" => String.to_integer(rss)
          }
        ]
      else
        _ -> []
      end
    end)
  end

  def verify_continuity!(before, next, content, clicks) do
    if before["boot_id"] in [nil, ""] or before["boot_id"] != next["boot_id"],
      do: raise("Guest rebooted or boot identity unavailable")

    for name <- ["driver", "server", "chromium"] do
      if get_in(before, ["processes", name]) == nil or
           get_in(before, ["processes", name]) != get_in(next, ["processes", name]),
         do: raise("#{name} restarted or process identity unavailable")
    end

    for key <- ["server_nonce", "browser_nonce"] do
      if get_in(before, ["page", key]) in [nil, ""] or
           get_in(before, ["page", key]) != get_in(next, ["page", key]),
         do: raise("Lost memory-only #{key}")
    end

    if next["edited_file"] != content or get_in(next, ["page", "clicks"]) != clicks,
      do: raise("Lost draft bytes, missing input or replayed input")

    :ok
  end

  def same_process?(before, next),
    do: before["pid"] == next["pid"] and before["start"] == next["start"]

  def decode_frame(frame, previous, sequence) do
    if frame["revision"] == 0 and is_integer(frame["sequence"]) and frame["sequence"] > previous and
         frame["input_sequence"] == sequence do
      image = Base.decode64!(frame["frame"])

      if not match?(<<255, 216, _::binary>>, image) or byte_size(image) > 700_000,
        do: raise("Invalid preview JPEG")

      image
    end
  end

  def await(fun, description, timeout_ms \\ 90_000),
    do: wait(fun, description, now_ms() + timeout_ms)

  defp wait(fun, description, deadline) do
    case fun.() do
      nil ->
        if now_ms() >= deadline, do: raise(description)
        Process.sleep(50)
        wait(fun, description, deadline)

      value ->
        value
    end
  end

  def now_ms, do: System.monotonic_time(:microsecond) / 1000
  def id, do: :crypto.strong_rand_bytes(16) |> Base.encode16(case: :lower)
end
