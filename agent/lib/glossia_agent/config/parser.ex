defmodule GlossiaAgent.Config.Parser do
  @moduledoc """
  GLOSSIA.md parsing -- splits TOML frontmatter, parses config, collects entries.
  Ported from agent/config.ts / cli/internal/glossia/config.go
  """

  alias GlossiaAgent.Config.ContentEntry
  alias GlossiaAgent.Config.LLMConfig

  defmodule ContentFile do
    @moduledoc "Parsed representation of a GLOSSIA.md or LANGUAGE.md file."
    defstruct [:path, :dir, :depth, :body, :llm, :content]

    @type t :: %__MODULE__{
            path: String.t(),
            dir: String.t(),
            depth: non_neg_integer(),
            body: String.t(),
            llm: LLMConfig.t(),
            content: [ContentEntry.t()]
          }
  end

  defmodule Entry do
    @moduledoc "A content entry with its origin file context."
    defstruct [
      :source,
      :path,
      :targets,
      :output,
      :exclude,
      :preserve,
      :frontmatter,
      :prompt,
      :check_cmd,
      :check_cmds,
      :origin_path,
      :origin_dir,
      :origin_depth,
      :index
    ]

    @type t :: %__MODULE__{
            source: String.t(),
            path: String.t(),
            targets: [String.t()],
            output: String.t(),
            exclude: [String.t()],
            preserve: [String.t()],
            frontmatter: String.t(),
            prompt: String.t(),
            check_cmd: String.t(),
            check_cmds: %{String.t() => String.t()},
            origin_path: String.t(),
            origin_dir: String.t(),
            origin_depth: non_neg_integer(),
            index: non_neg_integer()
          }
  end

  @doc "Split TOML frontmatter from content."
  @spec split_toml_frontmatter(String.t()) ::
          {:ok, String.t(), String.t()} | {:no_frontmatter, String.t()}
  def split_toml_frontmatter(contents) do
    lines = String.split(contents, "\n")

    case lines do
      ["+++" <> _ | rest] ->
        case Enum.find_index(rest, &(String.trim(&1) == "+++")) do
          nil ->
            raise "frontmatter start found but no closing +++"

          end_idx ->
            frontmatter = rest |> Enum.take(end_idx) |> Enum.join("\n")
            body = rest |> Enum.drop(end_idx + 1) |> Enum.join("\n")
            {:ok, frontmatter, body}
        end

      _ ->
        {:no_frontmatter, contents}
    end
  end

  @doc "Parse a GLOSSIA.md or LANGUAGE.md file into a ContentFile."
  @spec parse_content_file(String.t()) :: ContentFile.t()
  def parse_content_file(file_path) do
    raw = File.read!(file_path)

    {llm, content_entries, body} =
      case split_toml_frontmatter(raw) do
        {:ok, frontmatter, body} ->
          parsed = Toml.decode!(frontmatter)
          llm = LLMConfig.from_toml(parsed["llm"])

          raw_entries =
            (as_list(parsed["content"]) ++ as_list(parsed["translate"]))
            |> Enum.filter(&is_map/1)
            |> Enum.map(&ContentEntry.from_toml/1)

          # Apply defaults
          entries =
            Enum.map(raw_entries, fn entry ->
              entry =
                if String.trim(entry.source) == "",
                  do: %{entry | source: entry.path},
                  else: entry

              if entry.targets != [] && String.trim(entry.frontmatter) == "",
                do: %{entry | frontmatter: ContentEntry.frontmatter_preserve()},
                else: entry
            end)

          {llm, entries, body}

        {:no_frontmatter, body} ->
          {%LLMConfig{}, [], body}
      end

    abs_path = Path.expand(file_path)
    dir = Path.dirname(abs_path)

    %ContentFile{
      path: abs_path,
      dir: dir,
      depth: 0,
      body: body,
      llm: llm,
      content: content_entries
    }
  end

  @doc "Collect all entries from a list of content files, attaching origin metadata."
  @spec collect_entries([ContentFile.t()]) :: [Entry.t()]
  def collect_entries(content_files) do
    content_files
    |> Enum.flat_map(fn file ->
      file.content
      |> Enum.with_index()
      |> Enum.filter(fn {entry, _idx} -> ContentEntry.valid?(entry) end)
      |> Enum.map(fn {raw, idx} ->
        frontmatter =
          if String.trim(raw.frontmatter) == "" && raw.targets != [] do
            ContentEntry.frontmatter_preserve()
          else
            raw.frontmatter
          end

        %Entry{
          source: first_non_empty(raw.source, raw.path),
          path: first_non_empty(raw.path, raw.source),
          targets: raw.targets,
          output: raw.output,
          exclude: raw.exclude,
          preserve: raw.preserve,
          frontmatter: frontmatter,
          prompt: raw.prompt,
          check_cmd: raw.check_cmd,
          check_cmds: raw.check_cmds,
          origin_path: file.path,
          origin_dir: file.dir,
          origin_depth: file.depth,
          index: idx
        }
      end)
    end)
  end

  defp first_non_empty(a, b) do
    if String.trim(a || "") != "", do: a, else: b
  end

  defp as_list(nil), do: []
  defp as_list(list) when is_list(list), do: list
  defp as_list(_), do: []
end
