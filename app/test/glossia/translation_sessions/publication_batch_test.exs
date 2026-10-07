defmodule Glossia.TranslationSessions.PublicationBatchTest do
  use ExUnit.Case, async: true

  alias Glossia.TranslationSessions.PublicationBatch

  defp change(path), do: %{path: path, status: "added", content: path}

  defp recording_batch(opts, result \\ :ok) do
    test_pid = self()

    {:ok, batch} =
      PublicationBatch.start_link(
        fn changes ->
          send(test_pid, {:published, Enum.map(changes, & &1.path)})
          result
        end,
        opts
      )

    batch
  end

  test "publishes once the batch holds enough files" do
    batch = recording_batch(max_files: 2, max_interval_ms: :timer.hours(1))

    assert :ok = PublicationBatch.add(batch, [change("es/a.md"), change(".glossia/a.lock")])
    refute_received {:published, _paths}

    assert :ok = PublicationBatch.add(batch, [change("es/b.md")])
    assert_received {:published, [".glossia/a.lock", "es/a.md", "es/b.md"]}

    assert :ok = PublicationBatch.flush(batch)
    refute_received {:published, _paths}
  end

  test "publishes when the interval has passed since the last push" do
    batch = recording_batch(max_files: 100, max_interval_ms: 0)

    assert :ok = PublicationBatch.add(batch, [change("es/a.md")])
    assert_received {:published, ["es/a.md"]}
  end

  test "flush publishes whatever is still pending" do
    batch = recording_batch(max_files: 100, max_interval_ms: :timer.hours(1))

    assert :ok = PublicationBatch.add(batch, [change("es/a.md")])
    assert :ok = PublicationBatch.add(batch, [change("es/a.md"), change("ja/a.md")])
    assert :ok = PublicationBatch.flush(batch)

    assert_received {:published, ["es/a.md", "ja/a.md"]}
  end

  test "keeps changes pending after a failed push and reports it on flush" do
    batch =
      recording_batch([max_files: 1, max_interval_ms: :timer.hours(1)], {:error, :github_down})

    assert :ok = PublicationBatch.add(batch, [change("es/a.md")])
    assert_received {:published, ["es/a.md"]}

    assert {:error, :github_down} = PublicationBatch.flush(batch)
    assert_received {:published, ["es/a.md"]}
  end
end
