defmodule Glossia.Translations.SubprocessCaptureTest do
  use ExUnit.Case, async: true

  @tag :tmp_dir
  test "drains fast stdout and stderr captures beyond the flow-control window", %{tmp_dir: dir} do
    payload = :binary.copy(:binary.list_to_bin(Enum.to_list(0..255)), 256)
    path = Path.join(dir, "payload")
    File.write!(path, payload)

    for redirect <- ["", " >&2"], _ <- 1..10 do
      assert {^payload, 0} =
               MuonTrap.cmd("sh", ["-c", "cat \"$1\"#{redirect}", "capture", path],
                 into: "",
                 stderr_to_stdout: true,
                 timeout: 5_000
               )
    end

    assert {^payload, 7} =
             MuonTrap.cmd("sh", ["-c", "cat \"$1\"; exit 7", "capture", path],
               into: "",
               stderr_to_stdout: true,
               timeout: 5_000
             )
  end

  @tag :tmp_dir
  test "timeouts still terminate the supervised child", %{tmp_dir: dir} do
    pid_path = Path.join(dir, "pid")

    assert {_output, :timeout} =
             MuonTrap.cmd(
               "sh",
               ["-c", "echo $$ > \"$1\"; exec sleep 30", "capture", pid_path],
               into: "",
               timeout: 1_000
             )

    pid = pid_path |> File.read!() |> String.trim()

    assert {_output, status} =
             MuonTrap.cmd("kill", ["-0", pid], into: "", stderr_to_stdout: true, timeout: 5_000)

    assert status != 0
  end
end
