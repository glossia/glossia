defmodule Glossia.Translations.Locks do
  @moduledoc """
  Per-locale translation lockfiles under `.glossia/<source>/<locale>.lock`, used to
  skip re-translating unchanged files across runs.

  Adapted from the CLI (`cli/src/locks.rs`). Because these lockfiles are now
  server-private (the CLI no longer translates), the hash is a straightforward
  SHA-256 over the source content, provider, model, and resolved context — rather
  than the CLI's snapshot Merkle tree — while keeping the PO reference-line
  normalization so line-number churn does not force re-translation.

  PO catalogs additionally get a per-msgid map (`po_units`) alongside the
  whole-file hash. A `.pot` refresh that only changes a handful of msgids
  invalidates just those msgids' translations; every other locale keeps its
  existing msgstrs from the output file and the engine only ships the changed
  strings to the model.

  On top of that, `add_baseline/2` attaches the fields the Phase 0 baseline
  extension needs (see `plans/translation-history-reconciliation.md`):
  `source_commit_sha`, `translation_session_id`, `protection_state`, and a
  `baseline_schema_version` so future migrations can tell when a lock was
  written. A lock without these fields is a legacy lock; readers should treat
  its `protection_state` as `"unknown_provenance"` and its baseline commit as
  unknown.

  The `source_commit_sha` recorded here is the commit the translation RUN was
  executed against, not a per-segment baseline. For PO files whose status is
  partial preservation (unchanged msgids keep their prior msgstrs while
  changed msgids are retranslated), some preserved msgstrs may still represent
  an older source revision than the one stored here. Per-msgid provenance is
  Phase 2 work. Phase 0 readers must treat `source_commit_sha` as
  "most-recent-run SHA" rather than "the SHA each segment was translated from."

  Baseline target content is NOT stored in the lock. The three-way merge
  retrieves it from git via `output_hash` plus `source_commit_sha` lookup, so
  the lock remains a small pointer rather than a duplicate copy of every
  translated byte.
  """

  alias Glossia.Translations.Context
  alias Glossia.Translations.DependencyDiff
  alias Glossia.Translations.InputDetails
  alias Glossia.Translations.Format
  alias Glossia.Translations.Fingerprint
  alias Glossia.Translations.Po
  alias Glossia.Translations.Prompt

  @baseline_schema_version 1

  # Freshly recorded baselines use `recorded`. `active` is reserved for Phase 2
  # (externally edited content whose protection has been activated); `released`
  # and `superseded` are Phase 2 state transitions. `unknown_provenance` marks
  # a baseline we cannot vouch for — legacy locks and runs where
  # `source_commit_sha` was absent.
  @valid_protection_states ~w(recorded active released superseded unknown_provenance)

  @doc "Path to the lockfile for a source/locale under the repo root."
  def lock_path(root, source_path, locale) do
    Path.join([root, ".glossia", source_path, "#{locale}.lock"])
  end

  @doc "Reads and decodes the lockfile, or `nil` if absent/unreadable."
  def read_lock(root, source_path, locale) do
    path = lock_path(root, source_path, locale)

    with true <- File.exists?(path),
         {:ok, raw} <- File.read(path),
         {:ok, lock} <- JSON.decode(raw) do
      lock
    else
      _ -> nil
    end
  end

  @doc "Writes the lockfile (pretty JSON)."
  def write_lock(root, source_path, locale, lock) do
    path = lock_path(root, source_path, locale)
    File.mkdir_p!(Path.dirname(path))
    File.write!(path, pretty_json(lock) <> "\n")
    :ok
  end

  @doc "Whether the output is stale given the current input hash and output."
  def stale?(nil, _hash, _output_path, _output_hash), do: true

  # Preservation is an operational safety mechanism: changing how the runner
  # protects Markdown must not retranslate an otherwise valid repository. New
  # hashes intentionally omit that implementation version. Existing locks are
  # compared by dependency tree with the former version field ignored, so the
  # version 5 to 6 change does not invalidate every locale at once.
  def stale?(lock, %{hash: hash, tree: tree} = state, output_path, output_hash) do
    lock["output_path"] != output_path or lock["output_hash"] != output_hash or
      not (lock["hash"] == hash or compatible_hash_tree?(lock["hash_tree"], tree, state))
  end

  def stale?(lock, hash, output_path, output_hash) do
    lock["hash"] != hash or lock["output_path"] != output_path or
      lock["output_hash"] != output_hash
  end

  @doc """
  Explains a stale lock comparison without exposing source text or context values.

  Reasons describe fingerprint differences, not necessarily user edits: for example,
  an engine change can alter a validation fingerprint without changing a command.
  Call this only after assessment decides an item needs translation, since PO
  per-message preservation can override a whole-file mismatch.
  """
  def translation_reasons(nil, _state, _output_path, output_hash) do
    ["lockfile_missing"] ++ if(output_hash == "", do: ["output_missing"], else: [])
  end

  def translation_reasons(lock, %{tree: tree} = state, output_path, output_hash) do
    output_reasons =
      []
      |> add_reason(lock["output_path"] != output_path, "output_path_changed")
      |> add_reason(output_hash == "", "output_missing")
      |> add_reason(
        output_hash != "" and lock["output_hash"] != output_hash,
        "output_changed"
      )

    input_reasons =
      if lock["hash"] == state.hash or compatible_hash_tree?(lock["hash_tree"], tree, state) do
        []
      else
        case {get_in(lock, ["hash_tree", "root"]), tree["root"]} do
          {%{} = stored, %{} = current} ->
            stored_metadata =
              fingerprint_metadata(normalize_tree_for_compatibility(stored, state))

            current_metadata =
              fingerprint_metadata(normalize_tree_for_compatibility(current, state))

            (Map.keys(stored_metadata) ++ Map.keys(current_metadata))
            |> Enum.uniq()
            |> Enum.sort()
            |> Enum.flat_map(fn key ->
              stored = Map.get(stored_metadata, key, %{})
              current = Map.get(current_metadata, key, %{})

              if stored == current, do: [], else: fingerprint_reasons(key, stored, current)
            end)
            |> case do
              [] -> ["translation_inputs_changed"]
              reasons -> reasons
            end

          _ ->
            ["translation_inputs_changed"]
        end
      end

    Enum.uniq(output_reasons ++ input_reasons)
  end

  @doc "A durable, field-level explanation of the accepted/current input comparison."
  def translation_diff(lock, state, output_path, output_hash) do
    previous = lock && get_in(lock, ["hash_tree", "root"])
    current = state.tree["root"]

    {before, after_value} =
      if lock && is_nil(previous) do
        base = %{"kind" => "translation_input", "label" => current["label"], "children" => []}

        {Map.put(base, "metadata", %{"input_hash" => lock["hash"]}),
         Map.put(base, "metadata", %{"input_hash" => state.hash})}
      else
        {comparison_details(previous, state), comparison_details(current, state)}
      end

    input_diff = DependencyDiff.diff(before, after_value)
    output_before = if lock, do: output_node(lock["output_path"], lock["output_hash"])
    output_diff = DependencyDiff.diff(output_before, output_node(output_path, output_hash))

    tree =
      input_diff ||
        %{
          "kind" => "translation_input",
          "label" => current["label"],
          "change" => "changed",
          "fields" => [],
          "children" => [],
          "aggregate_only" => false
        }

    tree = update_in(tree, ["children"], &(&1 ++ List.wrap(output_diff)))
    tree = if input_diff || output_diff, do: tree

    %{
      "version" => 1,
      "baseline" =>
        cond do
          is_nil(lock) -> "missing_lockfile"
          is_nil(previous) -> "legacy_lockfile"
          true -> "recorded"
        end,
      "source_commit_sha" => lock && lock["source_commit_sha"],
      "translation_session_id" => lock && lock["translation_session_id"],
      "changed_fields" => DependencyDiff.field_count(tree),
      "tree" => tree
    }
  end

  defp output_node(path, hash),
    do: %{
      "kind" => "output",
      "label" => "output",
      "metadata" => %{"path" => path, "content_hash" => hash},
      "children" => []
    }

  defp comparison_details(nil, _state), do: nil

  defp comparison_details(node, state) do
    node |> normalize_tree_for_compatibility(state) |> restore_details(node)
  end

  defp restore_details(normalized, original) do
    normalized
    |> Map.put("details", original["details"] || %{})
    |> Map.put(
      "children",
      Enum.zip_with(normalized["children"], original["children"] || [], &restore_details/2)
    )
  end

  defp add_reason(reasons, true, reason), do: reasons ++ [reason]
  defp add_reason(reasons, false, _reason), do: reasons

  defp fingerprint_metadata(node) do
    children = Enum.reduce(node["children"] || [], %{}, &Map.merge(&2, fingerprint_metadata(&1)))
    Map.put(children, {node["kind"], node["label"]}, node["metadata"] || %{})
  end

  defp fingerprint_reasons({"source", _}, _, _), do: ["source_changed"]

  defp fingerprint_reasons({"translation_config", _}, stored, current) do
    (Map.keys(stored) ++ Map.keys(current))
    |> Enum.uniq()
    |> Enum.sort()
    |> Enum.reject(&(Map.get(stored, &1) == Map.get(current, &1)))
    |> Enum.map(fn
      "validation_hash" -> "validation_changed"
      key when key in ["provider", "model"] -> "model_changed"
      key when key in ["prompt_version", "segmentation_version"] -> "translation_engine_changed"
      _ -> "translation_settings_changed"
    end)
  end

  defp fingerprint_reasons({"context", "project"}, _, _), do: ["project_context_changed"]
  defp fingerprint_reasons({"context", "locale"}, _, _), do: ["locale_context_changed"]
  defp fingerprint_reasons({"context", "voice"}, _, _), do: ["voice_changed"]
  defp fingerprint_reasons({"context", "terminology"}, _, _), do: ["glossary_changed"]
  defp fingerprint_reasons({"decision_config", _}, _, _), do: ["quality_settings_changed"]
  defp fingerprint_reasons(_, _, _), do: ["translation_inputs_changed"]

  @doc """
  Whether anything OTHER than the source content or output file changed.

  A change to the glossary, voice, model, prompt, or any other translation
  configuration node in the hash tree means every msgstr produced under the
  old context is potentially wrong. A pure `msgid` addition (with the same
  context) does not: unchanged msgstrs can still be preserved through
  `po_units` per-message inspection.

  Compares the compatibility-normalized hash tree with the `source` node
  removed on both sides. Returns `true` when the two differ or when the lock
  is missing entirely.
  """
  def context_stale?(nil, _hash_state), do: true

  def context_stale?(lock, %{tree: %{"root" => current_root}} = state) do
    stored_root = get_in(lock, ["hash_tree", "root"])

    if is_nil(stored_root) do
      # Old lock format without a hash tree — treat as context-fresh, since
      # `stale?/4` will still catch source/output changes and the caller falls
      # back to the whole-file `hash` compare there.
      false
    else
      strip_source(normalize_tree_for_compatibility(stored_root, state)) !=
        strip_source(normalize_tree_for_compatibility(current_root, state))
    end
  end

  def context_stale?(_lock, _hash_state), do: false

  @doc false
  # Test hook: exposes the source-stripped normalized tree so a test can
  # assert on what `context_stale?/2` actually compares.
  def __strip_source_for_test__(node) do
    node
    |> normalize_tree_for_compatibility()
    |> strip_source()
  end

  @doc """
  Classifies a PO source against a lock and its current output.

  Returns one of:

    * `:fresh` — every unit's source hash matches the lock and the output
      carries a translation for it. Nothing to do.
    * `{:partial, %{stale_keys: [...], preserved: %{...}}}` — a subset of
      msgids need re-translation. The unchanged units' translations survive
      as `preserved`, keyed by unit key.
    * `:full` — no per-unit information (old lock, missing output, structural
      lock mismatch). Every msgid must be re-translated from scratch.

  Only used for PO items; other formats keep the whole-file `stale?/4` path.
  """
  def po_status(lock, source_content, output_content)
      when is_binary(source_content) do
    with {:ok, units} <- Po.translation_units(source_content),
         true <- has_po_units?(lock),
         true <- is_binary(output_content),
         {:ok, file_translations} <- Po.output_translations(output_content) do
      stored = Map.get(lock, "po_units") || %{}
      # Reshape target-shape translations back to source shape so per-unit
      # preservation lines up with the source's plural arity. See
      # `Po.align_translations/2` for the exact inverse.
      output_translations = Po.align_translations(file_translations, units)

      {stale, preserved} =
        Enum.reduce(units, {[], %{}}, fn unit, {stale, preserved} ->
          cond do
            Map.get(stored, unit.key) != unit.source_hash ->
              {[unit.key | stale], preserved}

            not Map.has_key?(output_translations, unit.key) ->
              {[unit.key | stale], preserved}

            missing_output_translation?(unit, output_translations) ->
              {[unit.key | stale], preserved}

            true ->
              {stale, Map.put(preserved, unit.key, Map.fetch!(output_translations, unit.key))}
          end
        end)

      cond do
        stale == [] -> :fresh
        true -> {:partial, %{stale_keys: Enum.reverse(stale), preserved: preserved}}
      end
    else
      _ -> :full
    end
  end

  defp has_po_units?(lock) when is_map(lock) do
    is_map(Map.get(lock, "po_units"))
  end

  defp has_po_units?(_lock), do: false

  # A msgid whose source string carries content but whose output translation
  # is the empty string is treated as never translated. Otherwise a member
  # hand-clearing a msgstr in a review would stick because per-unit checks
  # would blindly preserve the empty string forever.
  #
  # `Enum.zip/2` silently truncates on length mismatch, which is exactly the
  # class of bug that let a target-shape/source-shape length skew slip
  # through preservation and only surface later as a `rebuild_text_literals`
  # count mismatch. The invariant here (aligned translations are the same
  # length as the source's `sources`) is guaranteed by
  # `Po.align_translations/2`, but check it explicitly so any future misuse
  # sends the unit through the stale path instead of down-counting.
  defp missing_output_translation?(unit, output_translations) do
    translations = Map.fetch!(output_translations, unit.key)

    if length(translations) != length(unit.sources) do
      true
    else
      unit.sources
      |> Enum.zip(translations)
      |> Enum.any?(fn {source, translation} -> source != "" and translation == "" end)
    end
  end

  @doc """
  Builds `%{unit_key => source_hash}` from PO source content, or `nil` on
  parse failure.
  """
  def po_units_map(source_content) when is_binary(source_content) do
    {:ok, units} = Po.translation_units(source_content)
    Map.new(units, fn unit -> {unit.key, unit.source_hash} end)
  end

  @doc "Builds a lockfile map for a completed translation."
  def build_lock(provider, model, source_path, output_path, output_text, hash) do
    build_lock(provider, model, source_path, output_path, output_text, hash, nil, nil)
  end

  def build_lock(provider, model, source_path, output_path, output_text, hash, hash_tree) do
    build_lock(provider, model, source_path, output_path, output_text, hash, hash_tree, nil)
  end

  def build_lock(
        provider,
        model,
        source_path,
        output_path,
        output_text,
        hash,
        hash_tree,
        context_provenance
      ) do
    build_lock(
      provider,
      model,
      source_path,
      output_path,
      output_text,
      hash,
      hash_tree,
      context_provenance,
      nil
    )
  end

  def build_lock(
        provider,
        model,
        source_path,
        output_path,
        output_text,
        hash,
        hash_tree,
        context_provenance,
        po_units
      ) do
    base = %{
      "hash" => hash,
      "provider" => provider,
      "model" => model,
      "source_path" => normalize_slashes(source_path),
      "output_path" => normalize_slashes(output_path),
      "output_hash" => hash_string(output_text),
      "translated_at" => DateTime.utc_now() |> DateTime.to_iso8601(),
      "hash_tree" => hash_tree,
      "server_context" => context_provenance
    }

    if po_units, do: Map.put(base, "po_units", po_units), else: base
  end

  @doc """
  Attaches Phase 0 baseline fields to a lock built by `build_lock/*`.

  Required option: `:source_commit_sha` — the SHA the translation RUN was
  executed against (see the module doc for the caveat about PO preservation).
  A missing or blank SHA (`nil`, `""`) downgrades `protection_state` to
  `"unknown_provenance"` and leaves the SHA field `nil`; the write still
  succeeds so that in-progress development or tests without a webhook SHA
  don't tip over, but readers get the honest answer that the provenance is
  missing.

  Optional: `:translation_session_id`, `:protection_state`
  (`"recorded"` by default — a freshly written translation with intact
  baseline fields; must be one of `#{Enum.join(@valid_protection_states, " | ")}`).
  """
  def add_baseline(lock, opts) when is_map(lock) and is_list(opts) do
    unless Keyword.has_key?(opts, :source_commit_sha) do
      raise KeyError, key: :source_commit_sha, term: opts
    end

    source_commit_sha = normalize_sha(Keyword.get(opts, :source_commit_sha))
    translation_session_id = Keyword.get(opts, :translation_session_id)
    requested_state = Keyword.get(opts, :protection_state, "recorded")

    unless requested_state in @valid_protection_states do
      raise ArgumentError,
            "invalid protection_state #{inspect(requested_state)}; " <>
              "expected one of #{inspect(@valid_protection_states)}"
    end

    protection_state =
      if is_nil(source_commit_sha), do: "unknown_provenance", else: requested_state

    lock
    |> Map.put("baseline_schema_version", @baseline_schema_version)
    |> Map.put("source_commit_sha", source_commit_sha)
    |> Map.put("translation_session_id", translation_session_id)
    |> Map.put("protection_state", protection_state)
  end

  defp normalize_sha(nil), do: nil
  defp normalize_sha(""), do: nil
  defp normalize_sha(sha) when is_binary(sha), do: sha
  defp normalize_sha(_other), do: nil

  @doc """
  Baseline view of a lock. Returns a map with `:schema_version`,
  `:source_commit_sha`, `:translation_session_id`, and `:protection_state`, or
  `nil` if the lock is absent. A legacy lock (no baseline fields) reads back as
  `schema_version: 0`, `protection_state: "unknown_provenance"`, and the other
  fields `nil` — the honest answer when the machinery predates baseline
  recording.

  A non-map lock, or one whose `baseline_schema_version` is not a non-negative
  integer, is treated as corrupted and read back as `unknown_provenance` at
  `schema_version: 0` so a bad file can never masquerade as a trustworthy
  baseline.
  """
  def baseline(nil), do: nil

  def baseline(lock) when is_map(lock) do
    case Map.get(lock, "baseline_schema_version") do
      nil ->
        unknown_baseline(0)

      version when is_integer(version) and version >= 0 ->
        %{
          schema_version: version,
          source_commit_sha: Map.get(lock, "source_commit_sha"),
          translation_session_id: Map.get(lock, "translation_session_id"),
          protection_state: Map.get(lock, "protection_state", "unknown_provenance")
        }

      _corrupted ->
        unknown_baseline(0)
    end
  end

  def baseline(_other), do: unknown_baseline(0)

  defp unknown_baseline(schema_version) do
    %{
      schema_version: schema_version,
      source_commit_sha: nil,
      translation_session_id: nil,
      protection_state: "unknown_provenance"
    }
  end

  @doc "The baseline schema version this build of Glossia writes."
  def baseline_schema_version, do: @baseline_schema_version

  @doc "All `protection_state` values this build of Glossia will accept on write."
  def valid_protection_states, do: @valid_protection_states

  @doc """
  Builds the complete dependency tree for one translation work item.

  Only effective server context content participates in the root hash. Source
  voice and glossary version numbers remain in lockfile provenance, so an
  unrelated glossary edit does not make every translated file stale.
  """
  def build_hash_state(input) when is_map(input) do
    source_hash = source_hash(input.format, input.source_content)

    source_node =
      hash_node("source", input.source_path, %{"content_hash" => source_hash}, [])

    validation = %{
      check_cmd: Map.get(input, :check_cmd),
      check_cmds: Map.get(input, :check_cmds),
      validation: Map.get(input, :validation),
      validation_relative_path: Map.get(input, :validation_relative_path)
    }

    config_node =
      hash_node(
        "translation_config",
        "generation",
        %{
          "provider" => input.provider,
          "model" => input.model,
          "format" => input.format,
          "source_language" => input.source_language,
          "language" => input.language,
          "locale" => input.locale,
          "frontmatter_mode" => to_string(input.frontmatter_mode),
          "preserve" => input |> Map.get(:preserve, []) |> Enum.sort(),
          "custom_prompt_hash" => hash_string(input.custom_prompt || ""),
          "prompt_version" => Prompt.version(),
          "segmentation_version" => Format.segmentation_version(),
          "retries" => Map.get(input, :retries, 0),
          "validation_hash" => hash_json(validation)
        },
        []
      )

    server_hash_input = Context.hash_input(input.server_context)

    server_context_node =
      hash_node(
        "server_context",
        "organization",
        %{
          "compiler_version" => server_hash_input["compiler_version"],
          "selector_version" => server_hash_input["selector_version"]
        },
        [
          hash_node(
            "context",
            "voice",
            %{"content_hash" => server_hash_input["voice_content_hash"]},
            []
          ),
          # The label reads "terminology" for lockfile hash-tree backward
          # compatibility. Renaming it would flip every existing lockfile
          # stale for one deploy because it flows into the node hash.
          hash_node(
            "context",
            "terminology",
            %{"content_hash" => server_hash_input["glossary_content_hash"]},
            []
          )
        ]
      )

    context_node =
      hash_node("context_bundle", "context", %{}, [
        hash_node(
          "context",
          "project",
          %{"content_hash" => hash_string(input.context_body || "")},
          []
        ),
        hash_node(
          "context",
          "locale",
          %{"content_hash" => hash_string(input.locale_override_body || "")},
          []
        ),
        server_context_node
      ])

    children = [source_node, config_node, context_node]

    children =
      case Map.get(input, :decision_model) do
        nil ->
          children

        configuration ->
          children ++
            [
              hash_node(
                "decision_config",
                "quality",
                %{
                  "configuration_hash" => hash_json(configuration),
                  "rubric_version" => Glossia.Translations.Quality.version()
                },
                []
              )
            ]
      end

    root = hash_node("translation_input", input.source_path, %{}, children)

    review_metadata = %{
      {"translation_config", "generation"} => %{
        "validation_hash" => Fingerprint.legacy_hash(validation)
      },
      {"context", "terminology"} => %{
        "content_hash" => Context.review_glossary_hash(input.server_context)
      },
      {"decision_config", "quality"} => %{
        "configuration_hash" => Fingerprint.legacy_hash(Map.get(input, :decision_model))
      }
    }

    # These aliases are comparison-only, never written to a lockfile. The old
    # encoder ordered the four atom keys by VM-local atom creation order. Match
    # all 24 historical orders of the CURRENT settings, not arbitrary old hashes,
    # so deployment does not invalidate translations and real edits still do.
    legacy_hashes = %{
      "validation_hash" => legacy_hashes(validation),
      "glossary_content_hash" => %{
        canonical: server_hash_input["glossary_content_hash"],
        hashes: Context.legacy_glossary_hashes(input.server_context)
      }
    }

    legacy_hashes =
      case Map.get(input, :decision_model) do
        nil ->
          legacy_hashes

        configuration ->
          Map.put(legacy_hashes, "configuration_hash", legacy_hashes(configuration))
      end

    %{
      hash: root["hash"],
      review_hash: review_hash(root, review_metadata),
      tree: %{"root" => InputDetails.attach(root, input)},
      legacy_hashes: legacy_hashes
    }
  end

  def build_hash_state(
        format,
        source_path,
        source_content,
        provider,
        model,
        context_body,
        locale_override_body
      ) do
    build_hash_state(%{
      format: format,
      source_path: source_path,
      source_content: source_content,
      provider: provider,
      model: model,
      source_language: "",
      language: "",
      locale: "",
      frontmatter_mode: :preserve,
      preserve: [],
      custom_prompt: nil,
      context_body: context_body,
      locale_override_body: locale_override_body,
      server_context: Context.empty_bundle()
    })
  end

  defp hash_node(kind, label, metadata, children) do
    child_hashes = Enum.map(children, & &1["hash"])
    descriptor = %{kind: kind, label: label, metadata: metadata, child_hashes: child_hashes}
    hash = hash_json(descriptor)

    %{
      "kind" => kind,
      "label" => label,
      "hash" => hash,
      "metadata" => metadata,
      "children" => children
    }
  end

  # Preserve the original v1 review protocol, including nested metadata and
  # child digests. This intentionally retains v1's VM-local JSON key ordering;
  # canonicalizing it would invalidate answers already awaiting continuation.
  defp review_hash(node, replacements) do
    Fingerprint.legacy_hash(%{
      kind: node["kind"],
      label: node["label"],
      metadata:
        Map.merge(node["metadata"], Map.get(replacements, {node["kind"], node["label"]}, %{})),
      child_hashes: Enum.map(node["children"], &review_hash(&1, replacements))
    })
  end

  @doc "Hash of the translation input: source (format-normalized), provider, model, context."
  def build_hash(format, source_content, provider, model, context_body, locale_override_body) do
    [source_hash(format, source_content), provider, model, context_body, locale_override_body]
    |> Enum.join("\0")
    |> hash_string()
  end

  @doc "Hash of the output content."
  def output_hash(output_text), do: hash_string(output_text)

  @doc "Format-aware source hash (PO ignores line-number churn)."
  def source_hash("po", content), do: hash_string(normalized_po_source(content))
  def source_hash(_format, content), do: hash_string(content)

  defp hash_string(value), do: :crypto.hash(:sha256, value) |> Base.encode16(case: :lower)
  defp hash_json(value), do: Fingerprint.hash(value)

  defp legacy_hashes(settings) do
    %{
      canonical: hash_json(settings),
      hashes: Fingerprint.legacy_hashes(settings, Map.keys(settings))
    }
  end

  defp pretty_json(value), do: value |> pretty_encode(0) |> IO.iodata_to_binary()

  defp pretty_encode(value, depth) when is_map(value) do
    case value |> Map.to_list() |> Enum.sort_by(fn {key, _value} -> to_string(key) end) do
      [] ->
        "{}"

      entries ->
        [
          "{\n",
          entries
          |> Enum.map(fn {key, nested_value} ->
            [
              indent(depth + 1),
              JSON.encode_to_iodata!(key),
              ": ",
              pretty_encode(nested_value, depth + 1)
            ]
          end)
          |> Enum.intersperse(",\n"),
          "\n",
          indent(depth),
          "}"
        ]
    end
  end

  defp pretty_encode(value, depth) when is_list(value) do
    case value do
      [] ->
        "[]"

      values ->
        [
          "[\n",
          values
          |> Enum.map(fn nested_value ->
            [indent(depth + 1), pretty_encode(nested_value, depth + 1)]
          end)
          |> Enum.intersperse(",\n"),
          "\n",
          indent(depth),
          "]"
        ]
    end
  end

  defp pretty_encode(value, _depth), do: JSON.encode_to_iodata!(value)

  defp indent(depth), do: String.duplicate("  ", depth)

  # Collapses consecutive `#: ` reference runs into a single sorted/deduped line
  # and strips trailing `:<line-number>` from each reference.
  defp normalized_po_source(content) do
    content
    |> String.split("\n")
    |> normalize_lines([])
    |> Enum.reverse()
    |> Enum.join("\n")
  end

  defp normalize_lines([], acc), do: acc

  defp normalize_lines([line | rest], acc) do
    case strip_ref_prefix(line) do
      nil ->
        normalize_lines(rest, [line | acc])

      ref ->
        {refs, remaining} = collect_refs(rest, split_refs(ref))
        merged = "#: " <> (refs |> Enum.sort() |> Enum.dedup() |> Enum.join(" "))
        normalize_lines(remaining, [merged | acc])
    end
  end

  defp collect_refs([line | rest] = lines, acc) do
    case strip_ref_prefix(line) do
      nil -> {acc, lines}
      ref -> collect_refs(rest, acc ++ split_refs(ref))
    end
  end

  defp collect_refs([], acc), do: {acc, []}

  defp strip_ref_prefix("#: " <> rest), do: rest
  defp strip_ref_prefix(_line), do: nil

  defp split_refs(ref),
    do: ref |> String.split(~r/\s+/, trim: true) |> Enum.map(&normalize_reference/1)

  defp normalize_reference(ref) do
    case rsplit_once(ref, ":") do
      nil -> ref
      {rest, last} -> if Regex.match?(~r/^\d*$/, last), do: rest, else: ref
    end
  end

  defp rsplit_once(str, sep) do
    case :binary.matches(str, sep) do
      [] ->
        nil

      matches ->
        {start, len} = List.last(matches)
        {binary_part(str, 0, start), binary_part(str, start + len, byte_size(str) - start - len)}
    end
  end

  defp normalize_slashes(input), do: String.replace(input, "\\", "/")

  defp compatible_hash_tree?(%{"root" => stored_root}, %{"root" => current_root}, state) do
    normalize_tree_for_compatibility(stored_root, state) ==
      normalize_tree_for_compatibility(current_root, state)
  end

  defp compatible_hash_tree?(_stored, _current, _state), do: false

  defp normalize_tree_for_compatibility(node, state \\ %{}) do
    node
    |> Map.drop(["hash", "details"])
    |> update_in(["metadata"], fn metadata ->
      case {node["kind"], node["label"]} do
        {"translation_config", _} ->
          (metadata || %{})
          |> Map.delete("preservation_version")
          |> normalize_legacy_hash("validation_hash", state)

        {"decision_config", _} ->
          normalize_legacy_hash(metadata || %{}, "configuration_hash", state)

        {"context", "terminology"} ->
          normalize_legacy_hash(metadata || %{}, "content_hash", state, "glossary_content_hash")

        _ ->
          metadata
      end
    end)
    |> update_in(["children"], fn children ->
      Enum.map(children || [], &normalize_tree_for_compatibility(&1, state))
    end)
  end

  defp normalize_legacy_hash(metadata, key, state, alias_key \\ nil) do
    case get_in(state, [:legacy_hashes, alias_key || key]) do
      %{canonical: canonical, hashes: hashes} ->
        if MapSet.member?(hashes, metadata[key]),
          do: Map.put(metadata, key, canonical),
          else: metadata

      nil ->
        metadata
    end
  end

  # Drops the `source` child from a normalized tree, leaving config and
  # context. Used to distinguish "only source content changed" (which the PO
  # per-msgid path can handle) from "context / config changed" (which invalidates
  # every msgstr, no matter what its source hash is).
  defp strip_source(node) do
    node
    |> update_in(["children"], fn children ->
      children
      |> Enum.reject(&(Map.get(&1, "kind") == "source"))
      |> Enum.map(&strip_source/1)
    end)
  end
end
