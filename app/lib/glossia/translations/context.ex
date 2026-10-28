defmodule Glossia.Translations.Context do
  @moduledoc """
  Resolves versioned account context and compiles the small subset required by a
  translation.

  A translation run captures the latest voice and glossary version numbers. The
  database-owning node resolves those immutable versions once per locale. The
  isolated repository runner then matches the resolved glossary against source
  files locally, avoiding both repeated database queries and sending the
  repository's complete source corpus over the node connection.

  Glossary entries are selected deterministically from translatable source text,
  with longer phrases claiming overlapping matches before shorter terms. The
  engine narrows that file-level selection again for every translated segment
  and applies a fixed prompt budget.
  """

  alias Glossia.Accounts.{Account, Voice}
  alias Glossia.Glossaries
  alias Glossia.Translations.Fingerprint
  alias Glossia.Translations.PreservedTokens
  alias Glossia.Voices

  @compiler_version 3
  @selector_version 2
  @relay_timeout 30_000
  @word_grapheme ~r/^[\p{L}\p{N}_]$/u
  @unspaced_grapheme ~r/^[\p{Han}\p{Hiragana}\p{Katakana}\p{Hangul}\p{Thai}\p{Lao}\p{Khmer}\p{Myanmar}]$/u
  @unspaced_character_class "\\p{Han}\\p{Hiragana}\\p{Katakana}\\p{Hangul}\\p{Thai}\\p{Lao}\\p{Khmer}\\p{Myanmar}"
  @max_glossary_entries 50
  @max_glossary_prompt_bytes 12_000
  @max_voice_prompt_bytes 8_000
  @max_voice_scalar_bytes 80
  @truncation_marker " … [truncated]"

  @doc "The version of the deterministic server-context compiler."
  def compiler_version, do: @compiler_version

  @doc "The version of the glossary selection rules."
  def selector_version, do: @selector_version

  @doc "The maximum number of bytes of organization voice context in one prompt."
  def max_voice_prompt_bytes, do: @max_voice_prompt_bytes

  @doc "An explicit empty snapshot for callers that have no account context."
  def empty_snapshot do
    %{
      compiler_version: @compiler_version,
      voice_version: nil,
      glossary_version: nil
    }
  end

  @doc "An explicit empty bundle for work items with no server context."
  def empty_bundle(locale \\ "") do
    %{
      compiler_version: @compiler_version,
      selector_version: @selector_version,
      locale: locale,
      snapshot: empty_snapshot(),
      voice: nil,
      glossary: [],
      shadowed_glossary: []
    }
  end

  @doc """
  Captures immutable server context references for a translation run.

  The snapshot is captured before the isolated runner starts. Versioned content
  is then resolved once per target locale and remains fixed for the whole run.
  """
  def snapshot(%Account{} = account) do
    {:ok,
     %{
       compiler_version: @compiler_version,
       voice_version: Voices.latest_voice_version(account),
       glossary_version: Glossaries.latest_glossary_version(account),
       decision_model: Glossia.Decisions.configuration(account)
     }}
  end

  @doc "Captures a snapshot on the node that owns the account database."
  def snapshot_on(target_node, %Account{} = account) when target_node == node(),
    do: snapshot(account)

  def snapshot_on(target_node, %Account{} = account) when is_atom(target_node) do
    case :rpc.call(target_node, __MODULE__, :snapshot, [account], @relay_timeout) do
      {:badrpc, reason} -> {:error, {:context_relay_failed, reason}}
      result -> result
    end
  end

  @doc """
  Resolves context for a batch of work items.

  Voice and glossary are loaded once per locale. Matching still happens
  independently for every source.
  """
  def resolve_many(%Account{} = account, snapshot, requests)
      when is_map(snapshot) and is_list(requests) do
    locales = requests |> Enum.map(& &1.locale) |> Enum.uniq()
    locale_contexts = account |> resolve_locales(snapshot, locales) |> prepare_locale_contexts()

    bundles =
      Enum.map(requests, fn request ->
        build_bundle(snapshot, locale_contexts, request.locale, request.source, request.preserve)
      end)

    {:ok, bundles}
  end

  @doc "Loads the effective voice and glossary once for every requested locale."
  def resolve_locales(%Account{} = account, snapshot, locales)
      when is_map(snapshot) and is_list(locales) do
    locales
    |> Enum.uniq()
    |> Map.new(fn locale ->
      {locale,
       %{
         voice: resolve_voice(account, snapshot.voice_version, locale),
         glossary: resolve_glossary(account, snapshot.glossary_version, locale)
       }}
    end)
  end

  @doc "Loads locale context on the node that owns the account database."
  def resolve_locales_on(target_node, %Account{} = account, snapshot, locales)
      when target_node == node() do
    {:ok, resolve_locales(account, snapshot, locales)}
  end

  def resolve_locales_on(target_node, %Account{} = account, snapshot, locales)
      when is_atom(target_node) do
    case :rpc.call(
           target_node,
           __MODULE__,
           :resolve_locales,
           [account, snapshot, locales],
           @relay_timeout
         ) do
      {:badrpc, reason} -> {:error, {:context_relay_failed, reason}}
      result when is_map(result) -> {:ok, result}
      other -> {:error, {:context_relay_failed, {:unexpected_response, other}}}
    end
  end

  @doc """
  Compiles term matchers once after locale context reaches the repository runner.

  Compiled matchers remain process-local and are excluded from prompts,
  hashes, and lockfile provenance.
  """
  def prepare_locale_contexts(locale_contexts) when is_map(locale_contexts) do
    Map.new(locale_contexts, fn {locale, context} ->
      {locale, Map.update!(context, :glossary, &prepare_entries(&1 || []))}
    end)
  end

  @doc """
  Merges platform and repo entries for a single target locale.

  Repo entries take precedence when the source term matches case-insensitively.
  The displaced platform entries are returned as `shadowed` so callers can
  surface the resolution in the UI and the lockfile provenance.
  """
  def merge_glossaries(platform_entries, repo_entries)
      when is_list(platform_entries) and is_list(repo_entries) do
    repo_terms = MapSet.new(repo_entries, &normalized_term/1)

    {kept, shadowed} =
      Enum.split_with(platform_entries, fn entry ->
        not MapSet.member?(repo_terms, normalized_term(entry))
      end)

    %{entries: repo_entries ++ kept, shadowed: shadowed}
  end

  # The merge equivalence must match the source-matching equivalence in
  # `select_entries` (which uses regex `iu` — simple case-insensitive
  # comparison, not full Unicode case folding). `:string.casefold/1` folds
  # `ß` -> `ss` which the matcher does not, so a repository entry `STRASSE`
  # would silently shadow a platform entry `straße` that could then never
  # be matched. `String.downcase/1` behaves the same as the regex `iu`
  # flag for our purposes.
  defp normalized_term(%{term: term}) when is_binary(term), do: String.downcase(term)
  defp normalized_term(_), do: ""

  @doc """
  Builds one file-level bundle from already resolved locale context.

  `repo_entries` are the file's `L10N.md` glossary entries for this locale,
  already resolved by `RepoGlossary.resolve/3`. They are merged with the
  server glossary for this locale: for an identical source term (case-insensitively equal) the
  repository entry wins and the platform entry is recorded as shadowed. A
  repository entry with no translation for the locale yields to the platform.
  """
  def build_bundle(snapshot, locale_contexts, locale, source, preserve, repo_entries \\ [])
      when is_map(snapshot) and is_map(locale_contexts) and is_binary(locale) and
             is_binary(source) and is_list(preserve) and is_list(repo_entries) do
    context = Map.fetch!(locale_contexts, locale)

    repo = prepare_entries(repo_entries)

    merged = merge_glossaries(context.glossary || [], repo)

    %{
      compiler_version: @compiler_version,
      selector_version: @selector_version,
      locale: locale,
      snapshot: snapshot,
      voice: context.voice,
      glossary: select_entries(merged.entries, source, preserve),
      shadowed_glossary: select_shadowed(merged.shadowed, source, preserve)
    }
  end

  # A shadowed entry is only relevant to a file if the shadowing repo term
  # actually occurs in the file's source. Otherwise the file's provenance
  # would list every locale-level conflict, most of them unrelated. Reuses
  # the file-level matcher without the file's active-entry claim tracking.
  defp select_shadowed(entries, source, preserve) do
    text = translatable_text(source, preserve)
    casefolded_text = :string.casefold(text)

    Enum.filter(entries, fn entry ->
      valid_entry?(entry) and likely_present?(entry, text, casefolded_text)
    end)
  end

  @doc """
  Selects glossary entries that occur in translatable text.

  Matching is Unicode-aware, honors `case_sensitive`, excludes preserved token
  contents, and suppresses shorter terms when all their matches are contained in
  a longer selected phrase.
  """
  def select_entries(entries, source, preserve)
      when is_list(entries) and is_binary(source) and is_list(preserve) do
    text = translatable_text(source, preserve)
    casefolded_text = :string.casefold(text)

    entries
    |> Enum.filter(&valid_entry?/1)
    |> Enum.filter(&likely_present?(&1, text, casefolded_text))
    |> Enum.sort_by(
      &{
        -byte_size(&1.term),
        &1.term,
        &1.translation,
        &1.definition || "",
        &1.case_sensitive,
        &1.id || ""
      }
    )
    |> Enum.reduce({[], []}, fn entry, {selected, claimed_ranges} ->
      available_ranges =
        entry
        |> match_ranges(text)
        |> Enum.reject(fn candidate ->
          Enum.any?(claimed_ranges, &overlap?(&1, candidate))
        end)

      if available_ranges == [] do
        {selected, claimed_ranges}
      else
        selected_entry = Map.put(entry, :match_count, length(available_ranges))
        {[selected_entry | selected], available_ranges ++ claimed_ranges}
      end
    end)
    |> elem(0)
    |> Enum.reverse()
  end

  @doc """
  Renders only the server context relevant to one translation segment.

  Voice remains present for every segment. The file-level glossary candidates
  are matched again so a segment sees only the terms it contains.
  """
  def prompt_body(bundle, segment, preserve)
      when is_map(bundle) and is_binary(segment) and is_list(preserve) do
    prompt(bundle, segment, preserve).body
  end

  @doc """
  Renders one segment's context together with deterministic budget diagnostics.

  The diagnostics let the repository runner report clipping once per work item
  without logging once per segment or retry.
  """
  def prompt(bundle, segment, preserve)
      when is_map(bundle) and is_binary(segment) and is_list(preserve) do
    glossary = select_entries(bundle.glossary || [], segment, preserve)

    {voice_body, voice_truncated} = render_voice_with_budget(bundle.voice)
    {glossary_body, glossary_budget} = render_glossary_with_budget(glossary)

    body =
      [voice_body, glossary_body]
      |> Enum.reject(&(&1 == ""))
      |> Enum.join("\n\n")

    %{
      body: body,
      budget: Map.put(glossary_budget, :voice_truncated, voice_truncated)
    }
  end

  @doc """
  Returns raw-free provenance for the lockfile.

  The effective voice and glossary are represented by hashes. Raw server
  guidance and translated terms never need to be committed to the repository.
  The `glossary.applied` list records the namespaced ids that reached the
  file's prompt candidate pool, and `glossary.shadowed` records platform
  entries the repo displaced. Both are namespaced (`repo:<key>` or
  `account:<key>`) so consumers can render them without back-referencing the
  server.
  """
  def provenance(bundle) when is_map(bundle) do
    snapshot = bundle.snapshot || empty_snapshot()
    applied = bundle.glossary || []
    shadowed = Map.get(bundle, :shadowed_glossary, [])

    %{
      "compiler_version" => bundle.compiler_version || @compiler_version,
      "selector_version" => bundle.selector_version || @selector_version,
      "voice" => %{
        "version" => snapshot.voice_version,
        "content_hash" => content_hash(render_voice(bundle.voice))
      },
      "glossary" => %{
        "version" => snapshot.glossary_version,
        "content_hash" => content_hash(normalized_glossary(applied)),
        "applied" => Enum.map(applied, &namespaced_id_of/1) |> Enum.sort() |> Enum.uniq(),
        "shadowed" => Enum.map(shadowed, &namespaced_id_of/1) |> Enum.sort() |> Enum.uniq()
      }
    }
  end

  defp namespaced_id_of(entry) do
    case Map.get(entry, :namespaced_id) do
      value when is_binary(value) -> value
      _ -> "account:" <> to_string(Map.get(entry, :logical_key, Map.get(entry, :id, "")))
    end
  end

  @doc "Returns the effective content fingerprints that affect generated output."
  def hash_input(bundle) when is_map(bundle) do
    provenance = provenance(bundle)

    %{
      "compiler_version" => provenance["compiler_version"],
      "selector_version" => provenance["selector_version"],
      "voice_content_hash" => get_in(provenance, ["voice", "content_hash"]),
      "glossary_content_hash" => get_in(provenance, ["glossary", "content_hash"])
    }
  end

  @doc "Field-level provenance without private voice or glossary text."
  def input_details(bundle) do
    voice = bundle.voice

    voice_fields =
      if voice do
        fields =
          Map.new([:tone, :formality, :target_audience, :guidelines, :description], fn key ->
            {"#{key}_hash", Fingerprint.hash(Map.get(voice, key))}
          end)

        country = locale_country(Map.get(voice, :locale)) || sole_target_country(voice)
        note = country && get_in(voice, [:cultural_notes, country])
        Map.put(fields, "cultural_note_hash", Fingerprint.hash(note))
      else
        %{}
      end

    glossary =
      Map.new(bundle.glossary || [], fn entry ->
        id = namespaced_id_of(entry)
        id = if id == "account:", do: entry.term, else: id
        id = "entry:" <> Fingerprint.hash(id)

        {id,
         %{
           "term_hash" => Fingerprint.hash(entry.term),
           "translation_hash" => Fingerprint.hash(entry.translation),
           "definition_hash" => Fingerprint.hash(Map.get(entry, :definition)),
           "case_sensitive" => Map.get(entry, :case_sensitive, false)
         }}
      end)

    %{voice: voice_fields, glossary: glossary}
  end

  @doc "Comparison-only fingerprints for glossary records serialized by older VMs."
  def legacy_glossary_hashes(bundle) do
    bundle
    |> Map.get(:glossary, [])
    |> normalized_glossary()
    |> Fingerprint.legacy_hashes([:term, :definition, :case_sensitive, :translation])
  end

  @doc false
  def review_glossary_hash(bundle) do
    bundle
    |> Map.get(:glossary, [])
    |> normalized_glossary()
    |> Fingerprint.legacy_hash()
  end

  defp resolve_voice(_account, nil, _locale), do: nil

  defp resolve_voice(account, version, locale) do
    case Voices.get_resolved_voice_version(account, version, locale) do
      nil -> nil
      voice -> Map.put(voice, :locale, locale)
    end
  end

  defp resolve_glossary(_account, nil, _locale), do: []

  defp resolve_glossary(account, version, locale) do
    account
    |> Glossaries.get_resolved_glossary_version(version, locale)
    |> Map.get(:entries, [])
  end

  defp prepare_entries(entries) do
    Enum.map(entries, fn entry ->
      if valid_entry?(entry) do
        entry
        |> Map.put(:matcher, term_regex(entry.term, entry.case_sensitive))
        |> Map.put(:casefolded_needle, :string.casefold(entry.term))
      else
        entry
      end
    end)
  end

  defp valid_entry?(entry) do
    is_binary(entry.term) and String.trim(entry.term) != "" and
      is_binary(entry.translation) and String.trim(entry.translation) != ""
  end

  defp likely_present?(%{case_sensitive: true, term: term}, text, _casefolded_text),
    do: :binary.match(text, term) != :nomatch

  defp likely_present?(entry, _text, casefolded_text) do
    needle = Map.get_lazy(entry, :casefolded_needle, fn -> :string.casefold(entry.term) end)
    :binary.match(casefolded_text, needle) != :nomatch
  end

  defp match_ranges(entry, text) do
    matcher =
      case Map.fetch(entry, :matcher) do
        {:ok, matcher} -> matcher
        :error -> term_regex(entry.term, entry.case_sensitive)
      end

    matcher
    |> Regex.scan(text, return: :index, capture: :first)
    |> Enum.map(fn [{start, length}] -> %{start: start, length: length} end)
  end

  defp term_regex(term, case_sensitive) do
    left_boundary = boundary(:left, String.first(term))
    right_boundary = boundary(:right, String.last(term))
    flags = if case_sensitive, do: "u", else: "iu"

    Regex.compile!(left_boundary <> Regex.escape(term) <> right_boundary, flags)
  end

  defp boundary(_side, nil), do: ""
  defp boundary(_side, grapheme) when not is_binary(grapheme), do: ""

  defp boundary(side, grapheme) do
    cond do
      not Regex.match?(@word_grapheme, grapheme) ->
        ""

      Regex.match?(@unspaced_grapheme, grapheme) ->
        ""

      side == :left ->
        "(?:(?<![\\p{L}\\p{N}_])|(?<=[#{@unspaced_character_class}]))"

      side == :right ->
        "(?:(?![\\p{L}\\p{N}_])|(?=[#{@unspaced_character_class}]))"
    end
  end

  defp overlap?(left, right) do
    left.start < right.start + right.length and right.start < left.start + left.length
  end

  defp translatable_text(source, preserve) do
    source = String.replace_invalid(source)
    kinds = PreservedTokens.resolve(preserve)
    protection = PreservedTokens.protect(source, kinds)

    text =
      Enum.reduce(protection.replacements, protection.text, fn {marker, _value}, text ->
        String.replace(text, marker, String.duplicate(" ", byte_size(marker)))
      end)

    if "urls" in kinds do
      text
      |> PreservedTokens.values(["urls"])
      |> Enum.reduce(text, fn url, text ->
        String.replace(text, url, String.duplicate(" ", byte_size(url)))
      end)
    else
      text
    end
  end

  defp render_voice(voice), do: voice |> render_voice_with_budget() |> elem(0)

  defp render_voice_with_budget(nil), do: {"", false}

  defp render_voice_with_budget(voice) do
    country = locale_country(Map.get(voice, :locale)) || sole_target_country(voice)
    cultural_note = country && get_in(voice, [:cultural_notes, country])

    body =
      [
        "Organization voice:",
        labeled("Tone", voice.tone, @max_voice_scalar_bytes),
        labeled("Formality", voice.formality, @max_voice_scalar_bytes),
        labeled("Audience", voice.target_audience, Voice.target_audience_limit()),
        block(
          "Cultural guidance for #{bounded_text(country, @max_voice_scalar_bytes)}",
          cultural_note,
          Voice.cultural_note_limit()
        ),
        block("Voice guidelines", voice.guidelines, Voice.guidelines_limit()),
        block("Product context", voice.description, Voice.description_limit())
      ]
      |> Enum.reject(&is_nil/1)
      |> Enum.join("\n")
      |> bounded_text(@max_voice_prompt_bytes)

    truncated =
      over_limit?(voice.tone, @max_voice_scalar_bytes) or
        over_limit?(voice.formality, @max_voice_scalar_bytes) or
        over_limit?(voice.target_audience, Voice.target_audience_limit()) or
        over_limit?(country, @max_voice_scalar_bytes) or
        over_limit?(cultural_note, Voice.cultural_note_limit()) or
        over_limit?(voice.guidelines, Voice.guidelines_limit()) or
        over_limit?(voice.description, Voice.description_limit())

    {body, truncated}
  end

  defp render_glossary_with_budget([]) do
    {"",
     %{
       glossary_matched: 0,
       glossary_included: 0,
       glossary_omitted: 0,
       glossary_definitions_omitted: 0
     }}
  end

  defp render_glossary_with_budget(entries) do
    header =
      "Required glossary:\nUse each target term whenever its corresponding source term appears."

    prioritized =
      entries
      |> Enum.sort_by(fn entry ->
        {
          -Map.get(entry, :match_count, 0),
          -byte_size(entry.term),
          entry.term,
          entry.translation,
          entry.definition || "",
          entry.case_sensitive,
          entry.id || ""
        }
      end)
      |> Enum.take(@max_glossary_entries)

    {included, rendered_bytes} = fitting_glossary(prioritized, byte_size(header))

    {rendered_lines, definitions_included} =
      included
      |> add_fitting_definitions(rendered_bytes)

    body =
      """
      #{header}
      #{Enum.join(rendered_lines, "\n")}
      """
      |> String.trim()

    definitions_available =
      Enum.count(included, fn {entry, _line} -> optional_definition(entry.definition) != "" end)

    {body,
     %{
       glossary_matched: length(entries),
       glossary_included: length(included),
       glossary_omitted: length(entries) - length(included),
       glossary_definitions_omitted: definitions_available - definitions_included
     }}
  end

  defp fitting_glossary(entries, initial_bytes) do
    entries
    |> Enum.reduce({[], initial_bytes}, fn entry, {included, bytes} ->
      line = glossary_line(entry)
      next_bytes = bytes + 1 + byte_size(line)

      if next_bytes <= @max_glossary_prompt_bytes do
        {[{entry, line} | included], next_bytes}
      else
        {included, bytes}
      end
    end)
    |> then(fn {included, bytes} -> {Enum.reverse(included), bytes} end)
  end

  defp add_fitting_definitions(entries, initial_bytes) do
    entries
    |> Enum.map_reduce({initial_bytes, 0}, fn {entry, line}, {bytes, included_count} ->
      definition = optional_definition(entry.definition)
      next_bytes = bytes + byte_size(definition)

      if definition != "" and next_bytes <= @max_glossary_prompt_bytes do
        {line <> definition, {next_bytes, included_count + 1}}
      else
        {line, {bytes, included_count}}
      end
    end)
    |> then(fn {lines, {_bytes, included_count}} -> {lines, included_count} end)
  end

  defp glossary_line(entry) do
    suffix = if entry.case_sensitive, do: " (case-sensitive)", else: ""
    "- #{JSON.encode!(entry.term)} → #{JSON.encode!(entry.translation)}#{suffix}"
  end

  defp labeled(_label, value, _limit) when value in [nil, ""], do: nil

  defp labeled(label, value, limit),
    do: "- #{label}: #{bounded_text(value, limit)}"

  defp block(_label, value, _limit) when value in [nil, ""], do: nil

  defp block(label, value, limit),
    do: "#{label}:\n#{bounded_text(value, limit)}"

  defp optional_definition(value) when value in [nil, ""], do: ""
  defp optional_definition(value), do: "\n  Meaning: #{value |> to_string() |> String.trim()}"

  defp locale_country(locale) when is_binary(locale) do
    locale
    |> String.split(["-", "_"], trim: true)
    |> Enum.drop(1)
    |> Enum.find(&Regex.match?(~r/^(?:[A-Za-z]{2}|\d{3})$/, &1))
    |> case do
      nil -> nil
      region -> String.upcase(region)
    end
  end

  defp locale_country(_locale), do: nil

  defp sole_target_country(voice) do
    case Map.get(voice, :target_countries, []) do
      [country] when is_binary(country) and country != "" -> String.upcase(country)
      _ -> nil
    end
  end

  defp normalized_glossary(entries) do
    entries
    |> Enum.map(&Map.take(&1, [:term, :definition, :case_sensitive, :translation]))
    |> Enum.sort_by(&{&1.term, &1.translation, &1.definition || "", &1.case_sensitive})
  end

  defp bounded_text(value, limit) do
    text = value |> to_string() |> String.trim() |> String.replace_invalid()

    if byte_size(text) <= limit do
      text
    else
      prefix_limit = max(limit - byte_size(@truncation_marker), 0)
      utf8_prefix(text, prefix_limit) <> @truncation_marker
    end
  end

  defp over_limit?(value, _limit) when value in [nil, ""], do: false

  defp over_limit?(value, limit) do
    value
    |> to_string()
    |> String.trim()
    |> String.replace_invalid()
    |> byte_size()
    |> Kernel.>(limit)
  end

  defp utf8_prefix(_text, limit) when limit <= 0, do: ""

  defp utf8_prefix(text, limit) do
    size = min(byte_size(text), limit)
    valid_prefix(text, size)
  end

  defp valid_prefix(_text, size) when size <= 0, do: ""

  defp valid_prefix(text, size) do
    prefix = binary_part(text, 0, size)

    if String.valid?(prefix) do
      prefix
    else
      valid_prefix(text, size - 1)
    end
  end

  defp content_hash(value), do: Fingerprint.hash(value)
end
