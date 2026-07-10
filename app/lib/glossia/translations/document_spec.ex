defmodule Glossia.Translations.DocumentSpec do
  @moduledoc """
  Validates a parsed `GLOSSIA.md` document against its structural rules.

  Ported from the CLI (`cli/src/config/spec.rs`). A document is classified by its
  repo-relative path — the root `GLOSSIA.md` (global), a nested `.../GLOSSIA.md`
  (scoped), or a `.../GLOSSIA/<locale>.md` overlay — and validated accordingly.
  """

  alias Glossia.Translations.Frontmatter

  @locale_regex ~r/^[A-Za-z]{2,3}(?:[-_][A-Za-z0-9]{2,8})*$/

  @doc "Validates `frontmatter` given the document's repo-relative `relative_path`."
  @spec validate_document(String.t(), Frontmatter.t()) :: :ok | {:error, String.t()}
  def validate_document(relative_path, %Frontmatter{} = frontmatter) do
    case classify(relative_path) do
      {:ok, :global} -> validate_global(frontmatter)
      {:ok, :scoped} -> validate_shared(frontmatter)
      {:ok, {:locale_overlay, filename_locale}} -> validate_overlay(frontmatter, filename_locale)
      {:error, _} = error -> error
    end
  end

  @doc false
  def classify("GLOSSIA.md"), do: {:ok, :global}

  def classify(path) do
    cond do
      String.starts_with?(path, "GLOSSIA/") ->
        classify_overlay(String.replace_prefix(path, "GLOSSIA/", ""))

      String.starts_with?(path, "./GLOSSIA/") ->
        classify_overlay(String.replace_prefix(path, "./GLOSSIA/", ""))

      String.contains?(path, "/GLOSSIA/") ->
        case rsplit_once(path, "/GLOSSIA/") do
          {dir, filename} when dir != "" -> classify_overlay(filename)
          _ -> scoped_or_error(path)
        end

      true ->
        scoped_or_error(path)
    end
  end

  defp scoped_or_error(path) do
    if String.ends_with?(path, "/GLOSSIA.md") do
      {:ok, :scoped}
    else
      {:error, "unsupported Glossia document path #{path}"}
    end
  end

  defp classify_overlay(filename) do
    if String.ends_with?(filename, ".md") do
      locale = String.replace_suffix(filename, ".md", "")

      cond do
        locale == "" ->
          {:error, "locale overlay file name must not be empty"}

        Regex.match?(~r/[^A-Za-z0-9_-]/, locale) ->
          {:error, "locale overlay file name contains invalid characters"}

        true ->
          {:ok, {:locale_overlay, locale}}
      end
    else
      {:error, "unsupported locale overlay path GLOSSIA/#{filename}"}
    end
  end

  defp validate_global(%Frontmatter{source_language: nil}),
    do: {:error, "GLOSSIA.md must declare source_language"}

  defp validate_global(%Frontmatter{source_language: source_language} = frontmatter) do
    with :ok <- validate_locale_identifier("source_language", source_language) do
      validate_shared(frontmatter)
    end
  end

  defp validate_shared(%Frontmatter{} = frontmatter) do
    with :ok <- validate_model_identifier(frontmatter.model),
         :ok <- validate_validation(frontmatter.validation),
         :ok <- validate_sources(frontmatter.sources) do
      validate_targets(frontmatter.targets)
    end
  end

  defp validate_overlay(%Frontmatter{} = frontmatter, filename_locale) do
    with :ok <- validate_overlay_locale(frontmatter.locale, filename_locale),
         :ok <- validate_model_identifier(frontmatter.model) do
      validate_validation(frontmatter.validation)
    end
  end

  defp validate_overlay_locale(nil, _filename_locale), do: :ok

  defp validate_overlay_locale(locale, filename_locale) do
    with :ok <- validate_locale_identifier("locale", locale) do
      if locale == filename_locale do
        :ok
      else
        {:error, "locale overlay declares locale #{locale}, expected #{filename_locale}"}
      end
    end
  end

  defp validate_sources(nil), do: :ok

  defp validate_sources({:list, _}),
    do: {:error, "sources must be a mapping of source patterns to target path templates"}

  defp validate_sources({:map, m}) when map_size(m) == 0,
    do: {:error, "sources must contain at least one mapping"}

  defp validate_sources({:map, m}) do
    Enum.reduce_while(m, :ok, fn {pattern, target}, :ok ->
      cond do
        String.trim(pattern) == "" -> {:halt, {:error, "source patterns must be non-empty"}}
        String.trim(target) == "" -> {:halt, {:error, "target path templates must be non-empty"}}
        true -> {:cont, :ok}
      end
    end)
  end

  defp validate_targets(nil), do: :ok
  defp validate_targets({:list, []}), do: {:error, "targets must contain at least one locale"}

  defp validate_targets({:list, locales}) do
    Enum.reduce_while(locales, {:ok, MapSet.new()}, fn locale, {:ok, seen} ->
      case validate_locale_identifier("targets", locale) do
        :ok ->
          if MapSet.member?(seen, locale) do
            {:halt, {:error, "targets must not contain duplicate locales"}}
          else
            {:cont, {:ok, MapSet.put(seen, locale)}}
          end

        error ->
          {:halt, error}
      end
    end)
    |> case do
      {:ok, _seen} -> :ok
      error -> error
    end
  end

  defp validate_targets({:map, m}) do
    Enum.reduce_while(m, :ok, fn {locale, language}, :ok ->
      case validate_locale_identifier("targets", locale) do
        :ok ->
          if String.trim(language) == "" do
            {:halt, {:error, "target language labels must be non-empty"}}
          else
            {:cont, :ok}
          end

        error ->
          {:halt, error}
      end
    end)
  end

  defp validate_validation(nil), do: :ok
  defp validate_validation([]), do: {:error, "validation must contain at least one argument"}

  defp validate_validation(argv) when is_list(argv) do
    if Enum.any?(argv, &(String.trim(&1) == "")) do
      {:error, "validation arguments must be non-empty"}
    else
      :ok
    end
  end

  defp validate_model_identifier(nil), do: :ok

  defp validate_model_identifier(model) do
    if String.trim(model) == "" do
      {:error, "model must be a non-empty model identifier"}
    else
      :ok
    end
  end

  defp validate_locale_identifier(field, locale) do
    if Regex.match?(@locale_regex, locale) do
      :ok
    else
      {:error, "#{field} must be a valid locale identifier"}
    end
  end

  defp rsplit_once(str, sep) do
    case :binary.matches(str, sep) do
      [] ->
        nil

      matches ->
        {start, len} = List.last(matches)
        dir = binary_part(str, 0, start)
        filename = binary_part(str, start + len, byte_size(str) - start - len)
        {dir, filename}
    end
  end
end
