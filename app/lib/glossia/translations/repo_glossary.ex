defmodule Glossia.Translations.RepoGlossary do
  @moduledoc """
  Parses `.glossia/glossary.yaml` at the repository root into a normalized set
  of entries the resolver can merge with the platform glossary.

  File shape:

      entries:
        - id: commit           # optional; defaults to slugified source
          source: commit       # required
          case_sensitive: false  # optional (default false)
          definition: ...      # optional
          targets:
            es: confirmación
            zh-Hans: 提交

  Repository entries take precedence over platform entries for the same
  (source, target locale) after normalization. A repository entry that omits a
  target for a locale means "no repository opinion for this locale" — the
  platform's translation still applies. It is never an implicit block.

  Entry identifiers are namespaced (`repo:<logical-key>`) so the lockfile can
  distinguish them from platform entries without ambiguity.
  """

  alias Glossia.Accounts.GlossaryEntry

  @filename ".glossia/glossary.yaml"

  @doc "Returns the conventional file path inside a repository checkout."
  def default_relative_path, do: @filename

  @doc """
  Loads the repo glossary from a checkout root, or `{:ok, []}` when absent.

  A relative `override_path` (from the L10N.md `glossary` field) may point
  to a location other than the default. The path is validated to stay
  inside the checkout to avoid resolver-directed reads outside the repo.
  """
  def load(repo_path, override_path \\ nil) when is_binary(repo_path) do
    with {:ok, relative} <- resolve_relative(override_path),
         {:ok, absolute} <- resolve_absolute(repo_path, relative) do
      cond do
        not File.exists?(absolute) ->
          {:ok, []}

        true ->
          with {:ok, raw} <- File.read(absolute),
               {:ok, data} <- YamlElixir.read_from_string(raw),
               {:ok, entries} <- parse(data) do
            {:ok, entries}
          end
      end
    end
  end

  defp resolve_relative(nil), do: {:ok, @filename}

  defp resolve_relative(path) when is_binary(path) do
    cond do
      Path.type(path) != :relative ->
        {:error, "glossary path must be relative to the repository root"}

      true ->
        {:ok, path}
    end
  end

  defp resolve_absolute(repo_path, relative) do
    joined = Path.join(repo_path, relative)
    expanded = Path.expand(joined)
    root = Path.expand(repo_path)

    if String.starts_with?(expanded <> "/", root <> "/") do
      {:ok, expanded}
    else
      {:error, "glossary path escapes the repository root"}
    end
  end

  @doc "Parses an already-decoded YAML document into normalized entries."
  def parse(nil), do: {:ok, []}

  def parse(data) when is_map(data) do
    raw = data["entries"] || data[:entries] || []

    cond do
      not is_list(raw) ->
        {:error, "glossary `entries` must be a list"}

      true ->
        with {:ok, entries} <- Enum.reduce_while(raw, {:ok, []}, &parse_entry/2),
             :ok <- validate_unique_keys(entries) do
          {:ok, entries}
        end
    end
  end

  def parse(_other), do: {:error, "glossary file must be a mapping"}

  @doc """
  Projects the parsed entries into locale-resolved shape matching what
  `Glossia.Glossaries.get_resolved_glossary_version/3` returns for the
  platform: `%{id, logical_key, term, definition, case_sensitive, translation}`.

  Locale fallback follows the same rule the platform uses (region → language),
  so `zh-Hans-CN` falls back to `zh-Hans` and then `zh`. Entries without any
  matching target for the requested locale (after fallback) are omitted.
  """
  def resolve_for_locale(entries, locale) when is_list(entries) and is_binary(locale) do
    locale_candidates = locale_candidates(locale)
    ranks = locale_candidates |> Enum.with_index() |> Map.new()

    entries
    |> Enum.flat_map(fn entry ->
      case pick_target(entry.targets, ranks) do
        nil ->
          []

        {_rank, target_locale, translation} ->
          namespaced = namespaced_id(entry.logical_key)

          [
            %{
              id: namespaced,
              namespaced_id: namespaced,
              logical_key: entry.logical_key,
              origin: :repo,
              term: entry.source,
              definition: entry.definition,
              case_sensitive: entry.case_sensitive,
              translation: translation,
              translation_locale: target_locale
            }
          ]
      end
    end)
  end

  @doc "Builds the namespaced id for a repo entry key."
  def namespaced_id(logical_key) when is_binary(logical_key), do: "repo:" <> logical_key

  @doc """
  A stable content hash of the parsed entries, independent of file whitespace,
  comment reformatting, or entry order.
  """
  def content_hash(entries) when is_list(entries) do
    entries
    |> Enum.map(&normalize_for_hash/1)
    |> Enum.sort_by(& &1.logical_key)
    |> JSON.encode!()
    |> then(&:crypto.hash(:sha256, &1))
    |> Base.encode16(case: :lower)
  end

  defp parse_entry(item, {:ok, acc}) when is_map(item) do
    source = item["source"] || item[:source]

    cond do
      not is_binary(source) or source == "" ->
        {:halt, {:error, "glossary entry is missing `source`"}}

      true ->
        with {:ok, logical_key} <- parse_logical_key(item, source),
             {:ok, case_sensitive} <- parse_boolean(item, "case_sensitive", false),
             {:ok, definition} <- parse_optional_string(item, "definition"),
             {:ok, targets} <- parse_targets(source, item["targets"] || item[:targets]) do
          entry = %{
            logical_key: logical_key,
            source: source,
            case_sensitive: case_sensitive,
            definition: definition,
            targets: targets
          }

          {:cont, {:ok, [entry | acc]}}
        else
          {:error, _} = error -> {:halt, error}
        end
    end
  end

  defp parse_entry(_item, {:ok, _acc}),
    do: {:halt, {:error, "glossary entry must be a mapping"}}

  defp parse_logical_key(item, source) do
    case item["id"] || item[:id] do
      nil ->
        {:ok, GlossaryEntry.slugify(source)}

      value when is_binary(value) ->
        if String.trim(value) == "",
          do: {:ok, GlossaryEntry.slugify(source)},
          else: {:ok, value}

      other ->
        {:error, "glossary entry `#{source}` has a non-string `id`: #{inspect(other)}"}
    end
  end

  defp parse_boolean(item, key, default) do
    case Map.get(item, key, Map.get(item, String.to_existing_atom(key), default)) do
      true -> {:ok, true}
      false -> {:ok, false}
      nil -> {:ok, default}
      other -> {:error, "glossary field `#{key}` must be a boolean, got: #{inspect(other)}"}
    end
  rescue
    ArgumentError -> {:ok, default}
  end

  defp parse_optional_string(item, key) do
    case Map.get(item, key, Map.get(item, safe_to_atom(key))) do
      nil -> {:ok, nil}
      value when is_binary(value) -> {:ok, value}
      other -> {:error, "glossary field `#{key}` must be a string, got: #{inspect(other)}"}
    end
  end

  defp safe_to_atom(str) do
    String.to_existing_atom(str)
  rescue
    ArgumentError -> nil
  end

  defp parse_targets(_source, nil), do: {:ok, %{}}

  defp parse_targets(source, targets) when is_map(targets) do
    Enum.reduce_while(targets, {:ok, %{}}, fn {locale, translation}, {:ok, acc} ->
      cond do
        not is_binary(locale) ->
          {:halt,
           {:error,
            "glossary entry `#{source}` has a non-string locale key: #{inspect(locale)}"}}

        not is_binary(translation) ->
          {:halt,
           {:error,
            "glossary entry `#{source}` has a non-string translation for `#{locale}`: #{inspect(translation)}"}}

        String.trim(translation) == "" ->
          {:halt,
           {:error, "glossary entry `#{source}` has an empty translation for `#{locale}`"}}

        true ->
          {:cont, {:ok, Map.put(acc, locale, translation)}}
      end
    end)
  end

  defp parse_targets(source, other),
    do:
      {:error,
       "glossary entry `#{source}` has a `targets` that is not a mapping: #{inspect(other)}"}

  defp validate_unique_keys(entries) do
    entries
    |> Enum.frequencies_by(& &1.logical_key)
    |> Enum.find(fn {_key, count} -> count > 1 end)
    |> case do
      nil -> :ok
      {key, _} -> {:error, "glossary has duplicate entry id `#{key}`"}
    end
  end

  defp pick_target(targets, ranks) when is_map(targets) do
    targets
    |> Enum.map(fn {locale, translation} -> {Map.get(ranks, locale), locale, translation} end)
    |> Enum.filter(fn {rank, _, _} -> is_integer(rank) end)
    |> Enum.min_by(fn {rank, _, _} -> rank end, fn -> nil end)
  end

  defp pick_target(_targets, _ranks), do: nil

  defp locale_candidates(locale) do
    parts =
      locale
      |> String.replace("_", "-")
      |> String.split("-", trim: true)

    case parts do
      [] ->
        [locale]

      parts ->
        Enum.map(length(parts)..1//-1, fn count -> parts |> Enum.take(count) |> Enum.join("-") end)
    end
  end

  defp normalize_for_hash(entry) do
    targets =
      entry.targets
      |> Enum.sort_by(fn {locale, _} -> locale end)
      |> Enum.map(fn {locale, translation} -> [locale, translation] end)

    %{
      logical_key: entry.logical_key,
      source: entry.source,
      case_sensitive: !!entry.case_sensitive,
      definition: entry.definition || "",
      targets: targets
    }
  end
end
