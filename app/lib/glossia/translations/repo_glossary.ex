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

  @doc "Loads the repo glossary from a checkout root, or `{:ok, []}` when absent."
  def load(repo_path) when is_binary(repo_path) do
    path = Path.join(repo_path, @filename)

    cond do
      not File.exists?(path) ->
        {:ok, []}

      true ->
        with {:ok, raw} <- File.read(path),
             {:ok, data} <- YamlElixir.read_from_string(raw),
             {:ok, entries} <- parse(data) do
          {:ok, entries}
        end
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
          [
            %{
              id: namespaced_id(entry.logical_key),
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
        raw_key = item["id"] || item[:id]
        logical_key = if is_binary(raw_key) and raw_key != "", do: raw_key, else: GlossaryEntry.slugify(source)
        targets = parse_targets(item["targets"] || item[:targets] || %{})

        with :ok <- validate_targets(source, targets) do
          entry = %{
            logical_key: logical_key,
            source: source,
            case_sensitive: item["case_sensitive"] || item[:case_sensitive] || false,
            definition: item["definition"] || item[:definition],
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

  defp parse_targets(map) when is_map(map) do
    Map.new(map, fn {k, v} -> {to_string(k), to_string(v)} end)
  end

  defp parse_targets(_), do: %{}

  defp validate_targets(source, targets) do
    empty = for {locale, translation} <- targets, String.trim(translation) == "", do: locale

    case empty do
      [] -> :ok
      [locale | _] -> {:error, "glossary entry `#{source}` has an empty translation for `#{locale}`"}
    end
  end

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
      [] -> [locale]
      parts -> Enum.map(length(parts)..1//-1, fn count -> parts |> Enum.take(count) |> Enum.join("-") end)
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
