defmodule Glossia.SandboxBenchTest do
  use ExUnit.Case, async: true
  alias Glossia.SandboxBench, as: Bench

  test "continuity rejects restart, lost memory, changed draft and dropped input" do
    content = "{\"title\":\"Productos españoles\"}\n"

    before = %{
      "boot_id" => "guest-boot",
      "edited_file" => content,
      "page" => %{
        "server_nonce" => "server-memory",
        "browser_nonce" => "browser-memory",
        "clicks" => 4
      },
      "processes" => %{
        "driver" => %{"pid" => 1, "starttime" => "13"},
        "server" => %{"pid" => 8, "starttime" => "17"},
        "chromium" => %{"pid" => 11, "starttime" => "23"}
      }
    }

    next = put_in(before, ["page", "clicks"], 5)
    assert :ok == Bench.verify_continuity!(before, next, content, 5)

    for changed <- [
          put_in(next, ["boot_id"], "different-boot"),
          put_in(next, ["processes", "driver", "starttime"], "42"),
          put_in(next, ["processes", "server", "pid"], 9),
          put_in(next, ["processes", "chromium", "starttime"], "42"),
          put_in(next, ["page", "server_nonce"], "new-server"),
          put_in(next, ["page", "browser_nonce"], "new-browser"),
          put_in(next, ["edited_file"], String.trim(content)),
          put_in(next, ["page", "clicks"], 4)
        ] do
      assert_raise RuntimeError, fn -> Bench.verify_continuity!(before, changed, content, 5) end
    end

    refute Bench.same_process?(%{"pid" => 12, "start" => 99}, %{"pid" => 12, "start" => 100})
  end

  test "only a strictly newer frame acknowledging the exact input is accepted" do
    image = <<255, 216, 0, 1, 255, 217>>

    frame = %{
      "revision" => 0,
      "sequence" => 17,
      "input_sequence" => 3,
      "frame" => Base.encode64(image)
    }

    assert Bench.decode_frame(frame, 16, 3) == image
    assert Bench.decode_frame(frame, 17, 3) == nil
    assert Bench.decode_frame(frame, 18, 3) == nil
    assert Bench.decode_frame(frame, 16, 4) == nil
    assert Bench.decode_frame(Map.put(frame, "revision", 1), 16, 3) == nil
    assert Bench.decode_frame(Map.put(frame, "sequence", nil), 16, 3) == nil

    assert_raise RuntimeError, fn ->
      Bench.decode_frame(Map.put(frame, "frame", Base.encode64("not JPEG")), 16, 3)
    end
  end

  test "commands preserve binary output and report failures and timeouts" do
    assert Bench.command("printf", ["\\377\\330\\000x"]) == <<255, 216, 0, ?x>>

    assert_raise RuntimeError, ~r/failed \(7\).*failure/, fn ->
      Bench.command("sh", ["-c", "echo failure >&2; exit 7"])
    end

    assert_raise RuntimeError, fn -> Bench.command("sleep", ["5"], timeout: 20) end
  end

  test "durable JSON replacement preserves exact Unicode draft bytes" do
    directory = Path.join(System.tmp_dir!(), "glossia-journal-" <> Bench.id())
    File.mkdir!(directory)
    on_exit(fn -> File.rm_rf!(directory) end)
    path = Path.join(directory, "journal.json")
    Bench.write_json(path, %{"phase" => "Starting"})

    value = %{
      "phase" => "Running",
      "content" => "Productos españoles\n",
      "pending_sequence" => nil
    }

    Bench.write_json(path, value)
    assert Bench.read_json(path) == value
    assert File.ls!(directory) == ["journal.json"]
  end
end
