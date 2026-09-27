defmodule Glossia.Translations.RepoGlossary do
  @moduledoc """
  Resolves the glossary declared in a repository's `L10N.md` documents for one
  target locale.

  Terms are language-neutral and live in `L10N.md`; translations are
  language-specific and live in the `L10N/<locale>.md` overlays:

      # L10N.md
      ---
      glossary:
        - source: commit
          definition: The version-control action.
        - id: vcs-branch          # optional; defaults to the slugified source
          source: branch
          case_sensitive: false   # optional
      ---

      # L10N/es.md
      ---
      glossary:
        commit: commit            # keyed by a term's source ...
        vcs-branch: rama          # ... or by its id
        pull request: pull request   # a term only this locale declares
      ---

  Only terms with a translation for the locale produce an entry; the rest fall
  back to the server glossary. Entry identifiers are namespaced
  (`repo:<logical-key>`) so the lockfile can tell them apart from server
  entries.
  """

  alias Glossia.Accounts.GlossaryEntry

  @doc """
  Validates the merged `L10N.md` terms and the locale overlay's translations,
  and returns the locale-resolved entries in the shape the resolver merges
  with the server glossary.
  """
  def resolve(terms, translations, locale) when is_binary(locale) do
    with {:ok, terms} <- parse_terms(terms),
         {:ok, translations} <- parse_translations(translations) do
      {:ok, build_entries(terms, translations, locale)}
    end
  end

  @doc "Builds the namespaced id for a repository entry key."
  def namespaced_id(logical_key) when is_binary(logical_key), do: "repo:" <> logical_key

  defp build_entries(terms, translations, locale) do
    by_id = Map.new(terms, &{&1.logical_key, &1})
    by_source = Map.new(terms, &{&1.source, &1})

    translations
    |> Enum.sort_by(fn {key, _translation} -> key end)
    |> Enum.map(fn {key, translation} ->
      term = by_id[key] || by_source[key] || implicit_term(key)
      namespaced = namespaced_id(term.logical_key)

      %{
        id: namespaced,
        namespaced_id: namespaced,
        logical_key: term.logical_key,
        origin: :repo,
        term: term.source,
        definition: term.definition,
        case_sensitive: term.case_sensitive,
        translation: translation,
        translation_locale: locale
      }
    end)
    |> Enum.uniq_by(& &1.logical_key)
  end

  defp implicit_term(source) do
    %{
      logical_key: GlossaryEntry.slugify(source),
      source: source,
      case_sensitive: false,
      definition: nil
    }
  end

  defp parse_terms(nil), do: {:ok, []}

  defp parse_terms(raw) when is_list(raw) do
    with {:ok, terms} <- Enum.reduce_while(raw, {:ok, []}, &parse_term/2),
         :ok <- validate_unique_keys(terms) do
      {:ok, Enum.reverse(terms)}
    end
  end

  defp parse_terms(_other),
    do: {:error, "`glossary` in L10N.md must be a list of terms"}

  defp parse_term(item, {:ok, acc}) when is_map(item) do
    source = item["source"]

    cond do
      not is_binary(source) or String.trim(source) == "" ->
        {:halt, {:error, "glossary term is missing `source`"}}

      Map.has_key?(item, "targets") ->
        {:halt,
         {:error,
          "glossary term `#{source}` declares `targets`; translations belong in L10N/<locale>.md"}}

      true ->
        with {:ok, logical_key} <- parse_logical_key(item, source),
             {:ok, case_sensitive} <- parse_boolean(item, "case_sensitive", false),
             {:ok, definition} <- parse_optional_string(item, "definition") do
          term = %{
            logical_key: logical_key,
            source: source,
            case_sensitive: case_sensitive,
            definition: definition
          }

          {:cont, {:ok, [term | acc]}}
        else
          {:error, _} = error -> {:halt, error}
        end
    end
  end

  defp parse_term(_item, {:ok, _acc}),
    do: {:halt, {:error, "glossary term must be a mapping"}}

  defp parse_translations(nil), do: {:ok, %{}}

  defp parse_translations(raw) when is_map(raw) do
    Enum.reduce_while(raw, {:ok, %{}}, fn {key, translation}, {:ok, acc} ->
      cond do
        not is_binary(key) or String.trim(key) == "" ->
          {:halt, {:error, "glossary keys in L10N/<locale>.md must be non-empty terms"}}

        not is_binary(translation) ->
          {:halt,
           {:error,
            "glossary translation for `#{key}` must be a string, got: #{inspect(translation)}"}}

        String.trim(translation) == "" ->
          {:halt, {:error, "glossary translation for `#{key}` is empty"}}

        true ->
          {:cont, {:ok, Map.put(acc, key, translation)}}
      end
    end)
  end

  defp parse_translations(_other),
    do: {:error, "`glossary` in L10N/<locale>.md must map terms to translations"}

  defp parse_logical_key(item, source) do
    case item["id"] do
      nil ->
        {:ok, GlossaryEntry.slugify(source)}

      value when is_binary(value) ->
        if String.trim(value) == "",
          do: {:ok, GlossaryEntry.slugify(source)},
          else: {:ok, value}

      other ->
        {:error, "glossary term `#{source}` has a non-string `id`: #{inspect(other)}"}
    end
  end

  defp parse_boolean(item, key, default) do
    case Map.get(item, key) do
      nil -> {:ok, default}
      value when is_boolean(value) -> {:ok, value}
      other -> {:error, "glossary field `#{key}` must be a boolean, got: #{inspect(other)}"}
    end
  end

  defp parse_optional_string(item, key) do
    case Map.get(item, key) do
      nil -> {:ok, nil}
      value when is_binary(value) -> {:ok, value}
      other -> {:error, "glossary field `#{key}` must be a string, got: #{inspect(other)}"}
    end
  end

  defp validate_unique_keys(terms) do
    terms
    |> Enum.frequencies_by(& &1.logical_key)
    |> Enum.find(fn {_key, count} -> count > 1 end)
    |> case do
      nil -> :ok
      {key, _} -> {:error, "glossary has duplicate term id `#{key}`"}
    end
  end
end
