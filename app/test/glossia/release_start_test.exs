defmodule Glossia.ReleaseStartTest do
  use ExUnit.Case, async: true

  @tag :tmp_dir
  test "runner release node uses the pod address", %{tmp_dir: tmp_dir} do
    start_script = Path.expand("../../rel/overlays/bin/start", __DIR__)
    test_start_script = Path.join(tmp_dir, "start")
    test_release = Path.join(tmp_dir, "glossia")

    File.cp!(start_script, test_start_script)

    File.write!(test_release, """
    #!/bin/sh
    printf '%s\n' "$RELEASE_NODE"
    """)

    File.chmod!(test_start_script, 0o755)
    File.chmod!(test_release, 0o755)

    assert {"flame_runner@192.0.2.10\n", 0} =
             MuonTrap.cmd(test_start_script, [],
               env: [
                 {"POD_IP", "192.0.2.10"},
                 {"RELEASE_NODE", "flame_runner@$(POD_IP)"}
               ],
               into: ""
             )
  end

  @tag :tmp_dir
  test "runner release node preserves an explicit value", %{tmp_dir: tmp_dir} do
    start_script = Path.expand("../../rel/overlays/bin/start", __DIR__)
    test_start_script = Path.join(tmp_dir, "start")
    test_release = Path.join(tmp_dir, "glossia")

    File.cp!(start_script, test_start_script)

    File.write!(test_release, """
    #!/bin/sh
    printf '%s\n' "$RELEASE_NODE"
    """)

    File.chmod!(test_start_script, 0o755)
    File.chmod!(test_release, 0o755)

    assert {"custom@runner.example\n", 0} =
             MuonTrap.cmd(test_start_script, [],
               env: [
                 {"POD_IP", "192.0.2.10"},
                 {"RELEASE_NODE", "custom@runner.example"}
               ],
               into: ""
             )
  end
end
