defmodule Glossia.Translations.Chain do
  @moduledoc """
  Reads and resolves the `GLOSSIA.md` document tree from a checked-out repository.

  Ported from the CLI (`cli/src/config.rs`): discovers translation roots, resolves
  the frontmatter inheritance chain from the repo root down to a directory, and
  loads per-locale overlays. Operates on the repo cloned into the FLAME runner's
  filesystem.

  A parsed document is a map: `%{relative_path, raw_content, body, frontmatter}`.
  """

  alias Glossia.Translations.DocumentSpec
  alias Glossia.Translations.Frontmatter

  @doc "Reads, parses, and validates a `GLOSSIA.md`-style document at `path`."
  def parse_glossia_document(path, repo_root) do
    with {:ok, raw} <- File.read(path),
         {:ok, %{frontmatter: frontmatter, body: body}} <- Frontmatter.parse_content(raw) do
      relative_path = relative_to_root(repo_root, path)

      with :ok <- DocumentSpec.validate_document(relative_path, frontmatter) do
        {:ok,
         %{
           relative_path: relative_path,
           raw_content: raw,
           body: body,
           frontmatter: frontmatter
         }}
      end
    end
  end

  @doc """
  Resolves the frontmatter chain from the repo root down to `start_dir`.

  Returns `{:ok, %{merged_frontmatter, merged_body, files, validation}}` where
  deeper `GLOSSIA.md` files override shallower ones and `validation` is the
  deepest declared validation command.
  """
  def resolve_chain(start_dir, repo_root) do
    result =
      start_dir
      |> directories_up_to(repo_root)
      |> Enum.reduce_while(
        {:ok, %{files: [], merged: %Frontmatter{}, bodies: [], validation: nil}},
        fn dir, {:ok, acc} ->
          path = Path.join(dir, "GLOSSIA.md")

          if File.exists?(path) do
            case parse_glossia_document(path, repo_root) do
              {:ok, file} -> {:cont, {:ok, accumulate_chain(acc, file)}}
              {:error, _} = error -> {:halt, error}
            end
          else
            {:cont, {:ok, acc}}
          end
        end
      )

    with {:ok, acc} <- result do
      {:ok,
       %{
         merged_frontmatter: acc.merged,
         merged_body: Enum.join(acc.bodies, "\n\n"),
         files: acc.files,
         validation: acc.validation
       }}
    end
  end

  defp accumulate_chain(acc, file) do
    %{
      files: acc.files ++ [file],
      merged: Frontmatter.merge(acc.merged, file.frontmatter),
      bodies: append_body(acc.bodies, file.body),
      validation:
        declared_validation(file.frontmatter.validation, file.relative_path, acc.validation)
    }
  end

  @doc """
  Loads the `GLOSSIA/<locale>.md` overlay chain for `locale`.

  Returns `{:ok, %{merged_body, files, model, validation}}`. A `model` declared in
  a deeper overlay wins; an overlay that declares a mismatched locale is an error.
  """
  def load_locale_override(start_dir, repo_root, locale) do
    if String.contains?(locale, "/") or String.contains?(locale, "\\") do
      {:error, "invalid locale #{inspect(locale)}"}
    else
      result =
        start_dir
        |> directories_up_to(repo_root)
        |> Enum.reduce_while(
          {:ok, %{files: [], model: nil, validation: nil}},
          fn dir, {:ok, acc} ->
            path = Path.join([dir, "GLOSSIA", "#{locale}.md"])

            if File.exists?(path) do
              reduce_overlay(acc, path, repo_root, locale)
            else
              {:cont, {:ok, acc}}
            end
          end
        )

      with {:ok, acc} <- result do
        merged_body =
          acc.files
          |> Enum.map(&String.trim(&1.body))
          |> Enum.reject(&(&1 == ""))
          |> Enum.join("\n\n")

        {:ok,
         %{
           merged_body: merged_body,
           files: acc.files,
           model: acc.model,
           validation: acc.validation
         }}
      end
    end
  end

  defp reduce_overlay(acc, path, repo_root, locale) do
    case parse_glossia_document(path, repo_root) do
      {:ok, file} ->
        declared = file.frontmatter.locale

        if not is_nil(declared) and declared != locale do
          {:halt,
           {:error,
            "locale overlay #{file.relative_path} declares locale #{declared}, expected #{locale}"}}
        else
          {:cont,
           {:ok,
            %{
              files: acc.files ++ [file],
              model: file.frontmatter.model || acc.model,
              validation:
                declared_validation(
                  file.frontmatter.validation,
                  file.relative_path,
                  acc.validation
                )
            }}}
        end

      {:error, _} = error ->
        {:halt, error}
    end
  end

  @doc """
  Finds directories whose `GLOSSIA.md` declares sources or translate rules.

  Returns `{:ok, [dir]}` sorted by path. Skips dot-directories (e.g. `.git`).
  """
  def find_translation_roots(repo_root) do
    repo_root = Path.expand(repo_root)

    documents =
      [Path.join(repo_root, "GLOSSIA.md") | Path.wildcard(Path.join(repo_root, "**/GLOSSIA.md"))]
      |> Enum.filter(&File.regular?/1)
      |> Enum.uniq()

    result =
      Enum.reduce_while(documents, {:ok, []}, fn path, {:ok, acc} ->
        case parse_glossia_document(path, repo_root) do
          {:ok, file} ->
            if Frontmatter.has_sources?(file.frontmatter) or
                 Frontmatter.has_translation_rules?(file.frontmatter) do
              {:cont, {:ok, [Path.dirname(path) | acc]}}
            else
              {:cont, {:ok, acc}}
            end

          {:error, _} = error ->
            {:halt, error}
        end
      end)

    with {:ok, roots} <- result do
      {:ok, Enum.sort_by(roots, &normalize_slashes/1)}
    end
  end

  defp append_body(bodies, body) do
    if String.trim(body) == "", do: bodies, else: bodies ++ [body]
  end

  # A file's declared validation (deepest wins); keeps the previous when absent.
  defp declared_validation(nil, _relative_path, previous), do: previous

  defp declared_validation(argv, relative_path, _previous),
    do: %{argv: argv, relative_path: relative_path}

  # [repo_root, ..., start_dir] — root first, so deeper dirs override during merge.
  defp directories_up_to(start_dir, repo_root) do
    start_dir = Path.expand(start_dir)
    repo_root = Path.expand(repo_root)

    start_dir |> push_up(repo_root, []) |> Enum.reverse()
  end

  defp push_up(current, repo_root, acc) do
    acc = acc ++ [current]

    cond do
      current == repo_root -> acc
      Path.dirname(current) == current -> acc
      true -> push_up(Path.dirname(current), repo_root, acc)
    end
  end

  defp relative_to_root(repo_root, path) do
    repo_root
    |> Path.expand()
    |> then(&Path.relative_to(Path.expand(path), &1))
    |> normalize_slashes()
  end

  defp normalize_slashes(input), do: String.replace(input, "\\", "/")
end
