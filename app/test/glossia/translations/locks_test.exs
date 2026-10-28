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

  test "decision configuration invalidates accepted translations without changing unconfigured hashes" do
    input = %{
      format: "text",
      source_path: "guide.txt",
      source_content: "Hello",
      provider: "openai",
      model: "writer",
      source_language: "en",
      language: "Spanish",
      locale: "es",
      frontmatter_mode: :preserve,
      custom_prompt: nil,
      context_body: "",
      locale_override_body: "",
      server_context: Glossia.Translations.Context.empty_bundle("es")
    }

    original = Locks.build_hash_state(input)
    assert original == Locks.build_hash_state(Map.put(input, :decision_model, nil))

    configuration = %{
      handle: "quality",
      model: "typesafe/jev-latest",
      base_url: nil,
      decision_min_score: 7.0
    }

    configured = Locks.build_hash_state(Map.put(input, :decision_model, configuration))
    refute original.hash == configured.hash

    changed =
      Locks.build_hash_state(
        Map.put(input, :decision_model, %{configuration | decision_min_score: 8.0})
      )

    refute changed.hash == configured.hash
    lock = %{"hash_tree" => original.tree}
    assert Locks.context_stale?(lock, configured)
    assert Locks.context_stale?(%{"hash_tree" => configured.tree}, original)
  end

  test "human-review identities retain the original JSON protocol without changing lock trees" do
    context = Glossia.Translations.Context.empty_bundle("es")

    glossary = [
      %{term: "branch", translation: "rama", definition: "Git branch", case_sensitive: false}
    ]

    input = %{
      format: "text",
      source_path: "generation",
      source_content: "Launch a branch",
      provider: "openai",
      model: "writer",
      source_language: "en",
      language: "Spanish",
      locale: "es",
      frontmatter_mode: :preserve,
      custom_prompt: "Preserve placeholders",
      context_body: "Project guidance",
      locale_override_body: "Spanish guidance",
      check_cmd: "validate",
      validation: ["check", "--strict"],
      validation_relative_path: "tools/check",
      server_context: %{
        context
        | glossary: glossary,
          voice: %{
            tone: "Direct",
            formality: nil,
            target_audience: nil,
            guidelines: nil,
            description: nil,
            cultural_notes: %{}
          }
      }
    }

    decision = %{handle: "judge", model: "quality", base_url: nil, decision_min_score: 7.0}

    for configuration <- [nil, decision] do
      input = Map.put(input, :decision_model, configuration)
      state = Locks.build_hash_state(input)
      legacy = old_review_hash(state.tree["root"], input)

      assert state.review_hash == legacy

      assert Glossia.LinguisticReviews.fingerprint(state) ==
               Glossia.Translations.Checkpoints.key({"linguistic-review-v1", legacy})

      refute JSON.encode!(state.tree) =~ "review_hash"

      for edited <- [
            %{input | source_content: "Different source"},
            %{input | check_cmd: "other validator"},
            %{input | decision_model: %{decision | decision_min_score: 8.0}},
            %{input | server_context: %{input.server_context | glossary: []}}
          ] do
        refute Locks.build_hash_state(edited).review_hash == legacy
      end
    end
  end

  describe "translation_reasons/4" do
    setup do
      input = %{
        format: "text",
        source_path: "guide.txt",
        source_content: "Hello",
        provider: "openai",
        model: "writer",
        source_language: "en",
        language: "Spanish",
        locale: "es",
        frontmatter_mode: :preserve,
        custom_prompt: nil,
        context_body: "Project guidance",
        locale_override_body: "",
        server_context: Glossia.Translations.Context.empty_bundle("es")
      }

      state = Locks.build_hash_state(input)

      lock = %{
        "hash" => state.hash,
        "hash_tree" => state.tree,
        "output_path" => "es/guide.txt",
        "output_hash" => "output"
      }

      %{input: input, state: state, lock: lock}
    end

    test "explains missing and unreadable locks without assuming a source edit", %{state: state} do
      assert Locks.translation_reasons(nil, state, "es/guide.txt", "output") == [
               "lockfile_missing"
             ]

      assert Locks.translation_reasons(nil, state, "es/guide.txt", "") ==
               ["lockfile_missing", "output_missing"]
    end

    test "unchanged inputs have no reasons", %{state: state, lock: lock} do
      assert Locks.translation_reasons(lock, state, "es/guide.txt", "output") == []
    end

    test "reports source, model, context and validation differences together", %{
      input: input,
      lock: lock
    } do
      state =
        Locks.build_hash_state(
          %{
            input
            | source_content: "New source",
              model: "other",
              context_body: "New instructions"
          }
          |> Map.put(:check_cmd, "validate")
        )

      reasons = Locks.translation_reasons(lock, state, "es/guide.txt", "output")

      assert Enum.sort(reasons) ==
               Enum.sort([
                 "source_changed",
                 "model_changed",
                 "project_context_changed",
                 "validation_changed"
               ])

      refute Enum.any?(reasons, &String.contains?(&1, "New instructions"))
    end

    test "reports missing, edited and relocated output", %{state: state, lock: lock} do
      assert Locks.translation_reasons(lock, state, "es/guide.txt", "") == ["output_missing"]

      assert Locks.translation_reasons(lock, state, "es/guide.txt", "edited") == [
               "output_changed"
             ]

      assert Locks.translation_reasons(lock, state, "new/guide.txt", "output") == [
               "output_path_changed"
             ]
    end

    test "legacy locks do not invent a specific cause", %{state: state, lock: lock} do
      lock = lock |> Map.delete("hash_tree") |> Map.put("hash", "legacy")

      assert Locks.translation_reasons(lock, state, "es/guide.txt", "output") == [
               "translation_inputs_changed"
             ]
    end

    test "uses the same preservation compatibility normalization as staleness", %{
      state: state,
      lock: lock
    } do
      lock =
        update_in(lock, ["hash_tree", "root", "children"], fn children ->
          Enum.map(children, fn node ->
            if node["kind"] == "translation_config",
              do: put_in(node, ["metadata", "preservation_version"], 5),
              else: node
          end)
        end)
        |> Map.put("hash", "legacy-preservation-hash")

      refute Locks.stale?(lock, state, "es/guide.txt", "output")
      assert Locks.translation_reasons(lock, state, "es/guide.txt", "output") == []
    end

    test "all historical validation key orders remain current", %{
      input: input,
      state: state,
      lock: lock
    } do
      for hash <- state.legacy_hashes["validation_hash"].hashes do
        legacy = legacy_fingerprints(lock, %{"validation_hash" => hash})
        refute Locks.context_stale?(legacy, state)
        refute Locks.stale?(legacy, state, "es/guide.txt", "output")
        assert Locks.translation_reasons(legacy, state, "es/guide.txt", "output") == []
        assert Locks.stale?(legacy, state, "es/guide.txt", "edited")
        assert Locks.stale?(legacy, state, "moved/guide.txt", "output")

        source_edit = Locks.build_hash_state(%{input | source_content: "Updated source"})
        refute Locks.context_stale?(legacy, source_edit)
        assert Locks.stale?(legacy, source_edit, "es/guide.txt", "output")

        assert Locks.translation_reasons(legacy, source_edit, "es/guide.txt", "output") == [
                 "source_changed"
               ]

        validation_edit = Locks.build_hash_state(Map.put(input, :check_cmd, "validate"))
        assert Locks.context_stale?(legacy, validation_edit)

        assert Locks.translation_reasons(legacy, validation_edit, "es/guide.txt", "output") == [
                 "validation_changed"
               ]
      end
    end

    test "legacy decision and glossary orders preserve unchanged values but not edits", %{
      input: input,
      lock: lock
    } do
      glossary = [
        %{
          term: "lockfile",
          translation: "archivo de bloqueo",
          definition: nil,
          case_sensitive: false
        }
      ]

      context = %{input.server_context | glossary: glossary}

      decision = %{
        handle: "reviewer",
        model: "typesafe/jev",
        base_url: nil,
        decision_min_score: 7.0
      }

      input = Map.merge(input, %{server_context: context, decision_model: decision})
      state = Locks.build_hash_state(input)
      lock = %{lock | "hash" => state.hash, "hash_tree" => state.tree}

      for {quality_hash, glossary_hash} <-
            Enum.zip(
              state.legacy_hashes["configuration_hash"].hashes,
              state.legacy_hashes["glossary_content_hash"].hashes
            ) do
        legacy =
          legacy_fingerprints(lock, %{
            "configuration_hash" => quality_hash,
            "glossary_content_hash" => glossary_hash
          })

        refute Locks.context_stale?(legacy, state)
        refute Locks.stale?(legacy, state, "es/guide.txt", "output")
        assert Locks.translation_reasons(legacy, state, "es/guide.txt", "output") == []

        changed =
          Locks.build_hash_state(%{input | decision_model: %{decision | decision_min_score: 8.0}})

        assert Locks.context_stale?(legacy, changed)

        assert Locks.translation_reasons(legacy, changed, "es/guide.txt", "output") == [
                 "quality_settings_changed"
               ]

        changed_context = %{
          context
          | glossary: [%{hd(glossary) | translation: "fichero de bloqueo"}]
        }

        changed = Locks.build_hash_state(%{input | server_context: changed_context})
        assert Locks.context_stale?(legacy, changed)

        assert Locks.translation_reasons(legacy, changed, "es/guide.txt", "output") == [
                 "glossary_changed"
               ]
      end
    end

    test "records changed generation fields and exact validation sub-fields", %{
      input: input,
      state: state,
      lock: lock
    } do
      changed =
        Locks.build_hash_state(
          %{input | model: "new-writer"}
          |> Map.put(:check_cmds, %{"json" => "private validation command"})
        )

      diff = Locks.translation_diff(lock, changed, "es/guide.txt", "output")
      fields = diff_fields(diff["tree"])

      assert Enum.any?(
               fields,
               &(&1["field"] == "model" and &1["before"] == "writer" and
                   &1["after"] == "new-writer")
             )

      assert Enum.any?(fields, &(&1["field"] == "command_hash" and &1["change"] == "added"))
      refute JSON.encode!(diff) =~ "private validation command"
      assert Locks.translation_diff(lock, state, "es/guide.txt", "output")["tree"] == nil
    end

    test "identifies the changed instruction file and section, not unaffected context", %{
      input: input,
      lock: lock
    } do
      docs = [
        %{relative_path: "L10N.md", body: "# Tone\nFriendly.\n\n# Formatting\nKeep code.\n"}
      ]

      input = Map.merge(input, %{context_documents: docs, context_body: hd(docs).body})
      before = Locks.build_hash_state(input)
      lock = %{lock | "hash" => before.hash, "hash_tree" => before.tree}
      updated = [%{hd(docs) | body: String.replace(hd(docs).body, "Friendly.", "Direct.")}]

      current =
        Locks.build_hash_state(%{
          input
          | context_documents: updated,
            context_body: hd(updated).body
        })

      diff = Locks.translation_diff(lock, current, "es/guide.txt", "output")
      encoded = JSON.encode!(diff)
      assert encoded =~ "L10N.md"
      assert encoded =~ "# Tone"
      refute encoded =~ "# Formatting"
      refute encoded =~ "Friendly."
      refute encoded =~ "Direct."
      assert diff["changed_fields"] == 1
    end

    test "extra diagnostic coverage is not a generation dependency", %{state: state, lock: lock} do
      lock =
        lock
        |> Map.put("hash", "old-root")
        |> update_in(["hash_tree", "root"], &without_details/1)

      refute Locks.context_stale?(lock, state)
      refute Locks.stale?(lock, state, "es/guide.txt", "output")
      assert Locks.translation_diff(lock, state, "es/guide.txt", "output")["changed_fields"] == 0
    end

    test "private context values never enter lock diagnostics", %{input: input} do
      voice = %{
        tone: "SECRET-TONE",
        formality: "SECRET-FORMALITY",
        target_audience: "SECRET-AUDIENCE",
        guidelines: "SECRET-GUIDELINES",
        description: "SECRET-DESCRIPTION",
        cultural_notes: %{}
      }

      glossary = [
        %{
          namespaced_id: "account:entry-1",
          term: "SECRET-TERM",
          translation: "SECRET-TRANSLATION",
          definition: "SECRET-DEFINITION",
          case_sensitive: false
        }
      ]

      context = %{input.server_context | voice: voice, glossary: glossary}
      state = Locks.build_hash_state(%{input | server_context: context})
      encoded = JSON.encode!(state.tree)
      refute encoded =~ "SECRET-"
      assert encoded =~ "tone_hash"
      assert encoded =~ "translation_hash"
      refute encoded =~ "account:entry-1"
      assert encoded =~ "entry:"
    end

    test "reports removed quality configuration", %{input: input, state: state, lock: lock} do
      previous = Locks.build_hash_state(Map.put(input, :decision_model, %{model: "reviewer"}))
      lock = %{lock | "hash" => previous.hash, "hash_tree" => previous.tree}

      assert Locks.translation_reasons(lock, state, "es/guide.txt", "output") == [
               "quality_settings_changed"
             ]
    end
  end

  defp diff_fields(node), do: node["fields"] ++ Enum.flat_map(node["children"], &diff_fields/1)

  # The pre-canonicalization protocol, evaluated in this VM because v1's atom
  # key ordering was VM-local. Diagnostic details never participated in it.
  defp old_review_hash(node, input) do
    metadata =
      case {node["kind"], node["label"]} do
        {"translation_config", "generation"} ->
          settings =
            Map.new(
              [:check_cmd, :check_cmds, :validation, :validation_relative_path],
              &{&1, Map.get(input, &1)}
            )

          Map.put(node["metadata"], "validation_hash", old_json_hash(settings))

        {"decision_config", "quality"} ->
          Map.put(node["metadata"], "configuration_hash", old_json_hash(input.decision_model))

        {"context", "terminology"} ->
          entries =
            input.server_context.glossary
            |> Enum.map(&Map.take(&1, [:term, :definition, :case_sensitive, :translation]))
            |> Enum.sort_by(&{&1.term, &1.translation, &1.definition || "", &1.case_sensitive})

          Map.put(node["metadata"], "content_hash", old_json_hash(entries))

        _ ->
          node["metadata"]
      end

    old_json_hash(%{
      kind: node["kind"],
      label: node["label"],
      metadata: metadata,
      child_hashes: Enum.map(node["children"], &old_review_hash(&1, input))
    })
  end

  defp old_json_hash(value),
    do: :crypto.hash(:sha256, JSON.encode!(value)) |> Base.encode16(case: :lower)

  defp without_details(node) do
    node
    |> Map.delete("details")
    |> update_in(["children"], &Enum.map(&1, fn child -> without_details(child) end))
  end

  defp legacy_fingerprints(lock, replacements) do
    lock
    |> Map.put("hash", "historical-root-hash")
    |> update_in(["hash_tree", "root"], &replace_fingerprints(&1, replacements))
  end

  defp replace_fingerprints(node, replacements) do
    node =
      update_in(
        node,
        ["children"],
        &Enum.map(&1, fn child -> replace_fingerprints(child, replacements) end)
      )

    Enum.reduce(replacements, node, fn {key, hash}, node ->
      metadata_key = if key == "glossary_content_hash", do: "content_hash", else: key
      glossary? = key != "glossary_content_hash" or node["label"] == "terminology"

      if glossary? and Map.has_key?(node["metadata"], metadata_key),
        do: put_in(node, ["metadata", metadata_key], hash),
        else: node
    end)
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

  describe "context_stale?/2" do
    setup do
      hash_state =
        Locks.build_hash_state("md", "docs/a.md", "hello", "anthropic", "opus-4.7", "", "")

      %{state: hash_state}
    end

    test "returns true when the lock is missing", %{state: state} do
      assert Locks.context_stale?(nil, state)
    end

    test "returns false when the lock matches the current tree", %{state: state} do
      lock = %{"hash" => state.hash, "hash_tree" => state.tree}
      refute Locks.context_stale?(lock, state)
    end

    test "returns false when only the source content changed", %{state: state} do
      changed =
        Locks.build_hash_state("md", "docs/a.md", "hello world", "anthropic", "opus-4.7", "", "")

      lock = %{"hash" => state.hash, "hash_tree" => state.tree}
      refute Locks.context_stale?(lock, changed)
    end

    test "returns true when the provider (a config node) changed", %{state: state} do
      changed = Locks.build_hash_state("md", "docs/a.md", "hello", "openai", "opus-4.7", "", "")
      lock = %{"hash" => state.hash, "hash_tree" => state.tree}
      assert Locks.context_stale?(lock, changed)
    end

    test "returns true when the project context body changed", %{state: state} do
      changed =
        Locks.build_hash_state(
          "md",
          "docs/a.md",
          "hello",
          "anthropic",
          "opus-4.7",
          "new project context",
          ""
        )

      lock = %{"hash" => state.hash, "hash_tree" => state.tree}
      assert Locks.context_stale?(lock, changed)
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
