defmodule Glossia.ChangeSummary do
  @moduledoc false

  @voice_fields [:tone, :formality, :target_audience, :guidelines]

  @system_prompt """
  You are a version control assistant. Given a description of changes to a %{context}, \
  write a concise 1-sentence change note (under 120 characters) summarizing what changed. \
  Be specific but brief. Only output the summary, nothing else.\
  """

  @doc """
  Calls MiniMax to produce a concise change note from a diff description.

  Returns `{:ok, summary}` or `{:error, reason}`.

  ## Options

    * `:client` - LLM client module (default: `Glossia.Minimax`)
    * All other options are forwarded to the client's `chat/2`.
  """
  def generate(diff_description, context_label, opts \\ []) do
    {client, opts} = Keyword.pop(opts, :client, Glossia.Minimax)
    system = String.replace(@system_prompt, "%{context}", context_label)

    messages = [
      %{role: :system, content: system},
      %{role: :user, content: diff_description}
    ]

    opts = Keyword.put_new(opts, :max_tokens, 100)

    case client.chat(messages, opts) do
      {:ok, %{content: content}} -> {:ok, String.trim(content)}
      {:error, reason} -> {:error, reason}
    end
  end

  @doc """
  Builds a human-readable diff description for voice changes.
  """
  def describe_voice_changes(
        original_voice,
        current_params,
        original_overrides,
        current_overrides
      )

  def describe_voice_changes(nil, _current_params, _original_overrides, _current_overrides) do
    "Created initial voice configuration."
  end

  def describe_voice_changes(
        original_voice,
        current_params,
        original_overrides,
        current_overrides
      ) do
    base_changes =
      @voice_fields
      |> Enum.flat_map(fn field ->
        key = Atom.to_string(field)
        original = Map.get(original_voice, field) || ""
        current = current_params[key] || ""

        if original != current do
          label = field |> Atom.to_string() |> String.replace("_", " ")

          if original == "" do
            ["Set #{label} to '#{truncate(current)}'."]
          else
            ["Changed #{label} from '#{truncate(original)}' to '#{truncate(current)}'."]
          end
        else
          []
        end
      end)

    override_changes = describe_override_changes(original_overrides, current_overrides)

    changes = base_changes ++ override_changes

    if changes == [] do
      "No changes detected."
    else
      Enum.join(changes, " ")
    end
  end

  @doc """
  Builds a human-readable diff description for glossary changes.
  """
  def describe_glossary_changes(original_entries, current_entries) do
    orig_by_term = Map.new(original_entries, &{term_key(&1), &1})
    curr_by_term = Map.new(current_entries, &{term_key(&1), &1})

    orig_terms = MapSet.new(Map.keys(orig_by_term))
    curr_terms = MapSet.new(Map.keys(curr_by_term))

    added =
      curr_terms
      |> MapSet.difference(orig_terms)
      |> Enum.map(fn t -> "Added term '#{t}'." end)

    removed =
      orig_terms
      |> MapSet.difference(curr_terms)
      |> Enum.map(fn t -> "Removed term '#{t}'." end)

    modified =
      orig_terms
      |> MapSet.intersection(curr_terms)
      |> Enum.flat_map(fn t ->
        describe_entry_changes(orig_by_term[t], curr_by_term[t])
      end)

    changes = added ++ removed ++ modified

    if changes == [] do
      "No changes detected."
    else
      Enum.join(changes, " ")
    end
  end

  defp describe_entry_changes(orig, curr) do
    term = term_key(orig)
    changes = []

    orig_def = get_field(orig, :definition, "")
    curr_def = get_field(curr, :definition, "")

    changes =
      if orig_def != curr_def do
        changes ++ ["Updated definition for '#{term}'."]
      else
        changes
      end

    orig_cs = get_field(orig, :case_sensitive, false)
    curr_cs = get_field(curr, :case_sensitive, false)

    changes =
      if orig_cs != curr_cs do
        changes ++ ["Toggled case sensitivity for '#{term}'."]
      else
        changes
      end

    changes ++ describe_translation_changes(term, orig, curr)
  end

  defp describe_translation_changes(term, orig, curr) do
    orig_translations = translations_map(orig)
    curr_translations = translations_map(curr)

    orig_locales = MapSet.new(Map.keys(orig_translations))
    curr_locales = MapSet.new(Map.keys(curr_translations))

    added =
      curr_locales
      |> MapSet.difference(orig_locales)
      |> Enum.reject(&(&1 == ""))
      |> Enum.map(fn loc -> "Added #{loc} translation for '#{term}'." end)

    removed =
      orig_locales
      |> MapSet.difference(curr_locales)
      |> Enum.reject(&(&1 == ""))
      |> Enum.map(fn loc -> "Removed #{loc} translation for '#{term}'." end)

    modified =
      orig_locales
      |> MapSet.intersection(curr_locales)
      |> Enum.reject(&(&1 == ""))
      |> Enum.flat_map(fn loc ->
        if orig_translations[loc] != curr_translations[loc] do
          ["Updated #{loc} translation for '#{term}'."]
        else
          []
        end
      end)

    added ++ removed ++ modified
  end

  defp describe_override_changes(original_overrides, current_overrides) do
    orig_by_locale = Map.new(original_overrides, &{locale_key(&1), &1})
    curr_by_locale = Map.new(current_overrides, fn o -> {locale_key(o), o} end)

    orig_locales = MapSet.new(Map.keys(orig_by_locale))
    curr_locales = MapSet.new(Map.keys(curr_by_locale))

    added =
      curr_locales
      |> MapSet.difference(orig_locales)
      |> Enum.reject(&(&1 == ""))
      |> Enum.map(fn loc -> "Added locale override for #{loc}." end)

    removed =
      orig_locales
      |> MapSet.difference(curr_locales)
      |> Enum.reject(&(&1 == ""))
      |> Enum.map(fn loc -> "Removed locale override for #{loc}." end)

    modified =
      orig_locales
      |> MapSet.intersection(curr_locales)
      |> Enum.reject(&(&1 == ""))
      |> Enum.flat_map(fn loc ->
        orig = orig_by_locale[loc]
        curr = curr_by_locale[loc]

        @voice_fields
        |> Enum.flat_map(fn field ->
          ov = get_field(orig, field, "")
          cv = get_field(curr, field, "")

          if ov != cv do
            label = field |> Atom.to_string() |> String.replace("_", " ")
            ["Changed #{label} for #{loc} override."]
          else
            []
          end
        end)
      end)

    added ++ removed ++ modified
  end

  defp term_key(%{term: t}), do: t || ""
  defp term_key(%{"term" => t}), do: t || ""
  defp term_key(_), do: ""

  defp locale_key(%{locale: l}), do: l || ""
  defp locale_key(%{"locale" => l}), do: l || ""
  defp locale_key(_), do: ""

  defp get_field(map, key, default) when is_atom(key) do
    cond do
      is_map_key(map, key) -> Map.get(map, key) || default
      is_map_key(map, Atom.to_string(key)) -> Map.get(map, Atom.to_string(key)) || default
      true -> default
    end
  end

  defp translations_map(entry) do
    translations = get_field(entry, :translations, [])

    Map.new(translations, fn t ->
      locale = get_field(t, :locale, "")
      translation = get_field(t, :translation, "")
      {locale, translation}
    end)
  end

  defp truncate(str) when byte_size(str) > 50, do: String.slice(str, 0, 47) <> "..."
  defp truncate(str), do: str
end
