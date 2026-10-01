defmodule Glossia.Translations.LocksTest do
  use ExUnit.Case, async: true

  alias Glossia.Translations.Locks
  alias Glossia.Translations.Po

  # A minimal lock the way `RepositoryRun.write_lock` composes it — provider,
  # model, source/output paths, output content, and a hash. The baseline fields
  # go on top via `add_baseline/2`.
  defp minimal_lock do
    Locks.build_lock(
      "openai",
      "gpt-x",
      "docs/index.md",
      "docs/es/index.md",
      "hola",
      "input-hash-1234"
    )
  end

  describe "add_baseline/2" do
    test "attaches every baseline field on a freshly written lock" do
      lock =
        minimal_lock()
        |> Locks.add_baseline(
          source_commit_sha: "abc123",
          translation_session_id: "sess-42"
        )

      assert lock["baseline_schema_version"] == Locks.baseline_schema_version()
      assert lock["source_commit_sha"] == "abc123"
      assert lock["translation_session_id"] == "sess-42"
      assert lock["protection_state"] == "recorded"
    end

    test "defaults protection_state to \"recorded\" when omitted" do
      lock = Locks.add_baseline(minimal_lock(), source_commit_sha: "abc123")
      assert lock["protection_state"] == "recorded"
    end

    test "accepts an explicit protection_state override within the valid set" do
      for state <- Locks.valid_protection_states() do
        lock =
          Locks.add_baseline(minimal_lock(),
            source_commit_sha: "abc123",
            protection_state: state
          )

        # Nil-SHA takes precedence over any requested state, but a real SHA
        # must honor an explicit valid-state override.
        assert lock["protection_state"] == state
      end
    end

    test "rejects an unknown protection_state" do
      # Typos in a free-form string field would quietly become policy once
      # Phase 2 consumers switch on this value. The write path must raise.
      assert_raise ArgumentError, ~r/invalid protection_state/, fn ->
        Locks.add_baseline(minimal_lock(),
          source_commit_sha: "abc123",
          protection_state: "activated"
        )
      end
    end

    test "raises when source_commit_sha keyword is not supplied at all" do
      assert_raise KeyError, fn -> Locks.add_baseline(minimal_lock(), []) end
    end

    test "nil source_commit_sha downgrades protection_state to unknown_provenance" do
      # Codex caught this: `Keyword.fetch!` only guards against a missing key,
      # not a nil value. Live-translation tests build sessions without a commit
      # SHA, and we must not silently claim a trustworthy baseline for them.
      lock = Locks.add_baseline(minimal_lock(), source_commit_sha: nil)

      assert lock["source_commit_sha"] == nil
      assert lock["protection_state"] == "unknown_provenance"
    end

    test "empty-string source_commit_sha is treated as nil" do
      lock = Locks.add_baseline(minimal_lock(), source_commit_sha: "")

      assert lock["source_commit_sha"] == nil
      assert lock["protection_state"] == "unknown_provenance"
    end

    test "nil source_commit_sha overrides a requested recorded state" do
      lock =
        Locks.add_baseline(minimal_lock(),
          source_commit_sha: nil,
          protection_state: "recorded"
        )

      assert lock["protection_state"] == "unknown_provenance"
    end

    test "keeps existing lock fields intact" do
      base = minimal_lock()

      lock = Locks.add_baseline(base, source_commit_sha: "abc123")

      for key <- ["hash", "provider", "model", "source_path", "output_path", "output_hash"] do
        assert lock[key] == base[key]
      end
    end
  end

  describe "baseline/1" do
    test "returns nil for a missing lock" do
      assert Locks.baseline(nil) == nil
    end

    test "returns the recorded fields for a new-format lock" do
      lock = Locks.add_baseline(minimal_lock(), source_commit_sha: "abc123")

      assert Locks.baseline(lock) == %{
               schema_version: Locks.baseline_schema_version(),
               source_commit_sha: "abc123",
               translation_session_id: nil,
               protection_state: "recorded"
             }
    end

    test "reads a legacy lock (no baseline fields) as unknown_provenance at version 0" do
      assert Locks.baseline(minimal_lock()) == %{
               schema_version: 0,
               source_commit_sha: nil,
               translation_session_id: nil,
               protection_state: "unknown_provenance"
             }
    end

    test "treats a non-integer baseline_schema_version as corrupted" do
      # Codex found this: a string version would crash on case match. Corrupted
      # locks must never masquerade as a trustworthy baseline, so they read as
      # unknown_provenance.
      corrupted = Map.put(minimal_lock(), "baseline_schema_version", "one")

      assert Locks.baseline(corrupted) == %{
               schema_version: 0,
               source_commit_sha: nil,
               translation_session_id: nil,
               protection_state: "unknown_provenance"
             }
    end

    test "treats a negative baseline_schema_version as corrupted" do
      corrupted = Map.put(minimal_lock(), "baseline_schema_version", -1)
      assert Locks.baseline(corrupted).protection_state == "unknown_provenance"
    end

    test "treats non-map input as corrupted" do
      # `read_lock/3` returns whatever `JSON.decode` returns; a stray JSON array
      # or scalar must not crash downstream.
      assert Locks.baseline([1, 2, 3]).protection_state == "unknown_provenance"
      assert Locks.baseline("not a lock").protection_state == "unknown_provenance"
    end
  end

  describe "baseline persistence round-trip" do
    setup do
      root = System.tmp_dir!() |> Path.join("locks_test_#{System.unique_integer([:positive])}")
      File.mkdir_p!(root)
      on_exit(fn -> File.rm_rf!(root) end)
      %{root: root}
    end

    test "baseline fields survive write+read", %{root: root} do
      lock =
        minimal_lock()
        |> Locks.add_baseline(
          source_commit_sha: "abc123",
          translation_session_id: "sess-42"
        )

      Locks.write_lock(root, "docs/index.md", "es", lock)
      read = Locks.read_lock(root, "docs/index.md", "es")

      assert read["baseline_schema_version"] == Locks.baseline_schema_version()
      assert read["source_commit_sha"] == "abc123"
      assert read["translation_session_id"] == "sess-42"
      assert read["protection_state"] == "recorded"
    end

    test "reading a legacy lock file with no baseline fields still works", %{root: root} do
      legacy = minimal_lock()
      Locks.write_lock(root, "docs/index.md", "es", legacy)
      read = Locks.read_lock(root, "docs/index.md", "es")

      assert Locks.baseline(read).protection_state == "unknown_provenance"
      assert Locks.baseline(read).schema_version == 0
    end
  end

  # English source with a header, one singular msgid, and one plural entry.
  # `apply_plural_count/2` in `Po` writes target catalogs at the target
  # locale's declared `nplurals`, so a real-world catalog for ja/ko/zh-Hans
  # collapses to `msgstr[0]` only, and one for ru/pl/uk (3) or ar (6) pads by
  # duplicating the last kept form. This module verifies preservation
  # converges (returns `:fresh`) across all of those shapes for an unchanged
  # source.
  @source """
  msgid ""
  msgstr ""

  msgid "Hello"
  msgstr ""

  msgid "%d file"
  msgid_plural "%d files"
  msgstr[0] ""
  msgstr[1] ""
  """

  defp lock_for(source), do: %{"po_units" => Locks.po_units_map(source)}

  # Builds a valid target catalog for `locale` by writing English-shape
  # plurals and running the same `normalize_plural_forms/2` the write path
  # applies at the end of a translation, so the on-disk shape matches what
  # production produces.
  defp target_catalog(header_line, hello_msgstr, plural_forms) do
    plural_lines =
      plural_forms
      |> Enum.with_index()
      |> Enum.map(fn {msgstr, idx} -> ~s(msgstr[#{idx}] "#{msgstr}") end)
      |> Enum.join("\n")

    """
    msgid ""
    msgstr "#{header_line}"

    msgid "Hello"
    msgstr "#{hello_msgstr}"

    msgid "%d file"
    msgid_plural "%d files"
    #{plural_lines}
    """
  end

  describe "po_status/3 convergence across target nplurals" do
    for {locale, plural_forms} <- [
          {"ja", ["%d 個のファイル"]},
          {"ko", ["%d 파일"]},
          {"zh-Hans", ["%d 个文件"]},
          {"es", ["%d archivo", "%d archivos"]},
          {"ru", ["%d файл", "%d файла", "%d файлов"]},
          {"ar", ["%d ملف", "%d ملف", "%d ملفات", "%d ملفات", "%d ملفات", "%d ملفات"]}
        ] do
      # `nplurals=#{length(plural_forms)}` — one representative catalog per
      # plural-count class Glossia actually ships as a translation target
      # (`Glossia.I18n.common_translation_targets/0`).
      test "returns :fresh for #{locale} (nplurals=#{length(plural_forms)}) when source is unchanged" do
        # `Plural-Forms:` is what `Po.plural_count/2` reads first; the header
        # line encodes the target's declared count so the on-disk file is
        # internally consistent.
        header =
          "Language: #{unquote(locale)}\\nPlural-Forms: nplurals=#{unquote(length(plural_forms))}; plural=0;\\n"

        target = target_catalog(header, "hello-translated", unquote(plural_forms))

        assert Locks.po_status(lock_for(@source), @source, target) == :fresh
      end
    end
  end

  describe "po_status/3 stale detection" do
    test "marks a changed msgid stale, preserves the plural entry across nplurals=1 collapse" do
      # Simulates the failing production shape: source gets a new msgid,
      # target is a ja catalog (nplurals=1) with the previous entries.
      updated_source = @source <> "\nmsgid \"Bye\"\nmsgstr \"\"\n"

      ja_target =
        target_catalog(
          "Language: ja\\nPlural-Forms: nplurals=1; plural=0;\\n",
          "こんにちは",
          ["%d 個のファイル"]
        )

      status = Locks.po_status(lock_for(@source), updated_source, ja_target)
      assert {:partial, %{stale_keys: [_bye_key], preserved: preserved}} = status

      {:ok, source_units} = Po.translation_units(updated_source)
      plural_unit = Enum.find(source_units, &(length(&1.sources) > 1))

      # Preserved plural translations are inflated to source shape so
      # downstream rebuild counts match. The padding duplicates the last
      # target msgstr, mirroring `Po.apply_plural_count/2`'s pad-on-write.
      assert Map.fetch!(preserved, plural_unit.key) ==
               ["%d 個のファイル", "%d 個のファイル"]
    end

    test "marks a hand-cleared msgstr stale even when the source is unchanged" do
      target =
        target_catalog(
          "Language: es\\nPlural-Forms: nplurals=2; plural=(n != 1);\\n",
          "",
          ["%d archivo", "%d archivos"]
        )

      {:partial, %{stale_keys: stale, preserved: preserved}} =
        Locks.po_status(lock_for(@source), @source, target)

      {:ok, [_header, hello, plural]} = Po.translation_units(@source)

      assert hello.key in stale
      refute Map.has_key?(preserved, hello.key)
      # The plural entry is fully translated and stays preserved.
      assert Map.fetch!(preserved, plural.key) == ["%d archivo", "%d archivos"]
    end
  end

  describe "po_status/3 aggregate-count invariant (matches rebuild_text_literals expectations)" do
    for {locale, plural_forms} <- [
          {"ja", ["%d 個のファイル"]},
          {"es", ["%d archivo", "%d archivos"]},
          {"ru", ["%d файл", "%d файла", "%d файлов"]}
        ] do
      # Whenever preservation returns partial, the total number of preserved
      # + newly-translated literals must equal what `rebuild_text_literals/2`
      # counts against on the source tree. This is the exact quantity whose
      # skew produced the `catalog-rebuild-count` failure in production.
      test "preserved+stale totals match source literal count for #{locale}" do
        updated_source = @source <> "\nmsgid \"Bye\"\nmsgstr \"\"\n"

        header =
          "Language: #{unquote(locale)}\\nPlural-Forms: nplurals=#{unquote(length(plural_forms))}; plural=0;\\n"

        target = target_catalog(header, "hello-t", unquote(plural_forms))

        {:partial, %{stale_keys: stale_keys, preserved: preserved}} =
          Locks.po_status(lock_for(@source), updated_source, target)

        {:ok, source_units} = Po.translation_units(updated_source)
        units_by_key = Map.new(source_units, &{&1.key, &1})

        preserved_total = preserved |> Map.values() |> Enum.map(&length/1) |> Enum.sum()

        stale_total =
          stale_keys
          |> Enum.map(fn key -> length(Map.fetch!(units_by_key, key).sources) end)
          |> Enum.sum()

        # `rebuild_text_literals/2`'s expected count computed from source.
        expected =
          Enum.reduce(source_units, 0, fn unit, acc ->
            if unit.header?, do: acc + 1, else: acc + length(unit.sources)
          end)

        assert preserved_total + stale_total == expected
      end
    end
  end

  describe "po_status/3 degrades gracefully on non-invertible target shapes" do
    test "a plural unit whose target has zero translations is dropped and retranslated" do
      # A pathological target where a plural entry has no msgstr at all.
      # Alignment cannot invent content, so the unit is treated as absent
      # from the file and the preservation path re-translates it — safer
      # than either raising or silently preserving `[]`.
      broken_target = """
      msgid ""
      msgstr "Language: ja\\nPlural-Forms: nplurals=1; plural=0;\\n"

      msgid "Hello"
      msgstr "こんにちは"

      msgid "%d file"
      msgid_plural "%d files"
      """

      {:ok, [_header, _hello, plural]} = Po.translation_units(@source)

      assert {:partial, %{stale_keys: stale, preserved: preserved}} =
               Locks.po_status(lock_for(@source), @source, broken_target)

      assert plural.key in stale
      refute Map.has_key?(preserved, plural.key)
    end
  end
end
