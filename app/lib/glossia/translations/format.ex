defmodule Glossia.Translations.Format do
  @moduledoc """
  Content format detection and classification.

  Ported from the CLI (`cli/src/format.rs`) so the server-side planner classifies
  source files identically. Formats are the string values understood by
  `Glossia.Translations.Prompt`: `"markdown"`, `"json"`, `"yaml"`, `"po"`,
  `"text"`.
  """

  @formats ~w(markdown json yaml po text)
  @structured ~w(json yaml po)
  @supported_extensions ~w(md markdown json yaml yml po pot txt text)
  @segmentation_version 1

  @doc "All supported format strings."
  def formats, do: @formats

  @doc "Version of the format segmentation rules used by translation locks."
  def segmentation_version, do: @segmentation_version

  @doc "Detects the format from a file path's extension (case-insensitive)."
  def detect(path) do
    case path |> Path.extname() |> String.trim_leading(".") |> String.downcase() do
      ext when ext in ~w(md markdown) -> "markdown"
      "json" -> "json"
      ext when ext in ~w(yaml yml) -> "yaml"
      ext when ext in ~w(po pot) -> "po"
      _ -> "text"
    end
  end

  @doc "Whether a path has a built-in format adapter."
  def supported_path?(path) do
    path
    |> Path.extname()
    |> String.trim_leading(".")
    |> String.downcase()
    |> then(&(&1 in @supported_extensions))
  end

  @doc "Whether a format has machine-parseable structure (json/yaml/po)."
  def structured?(format), do: format in @structured

  @doc """
  Returns the content segmentation policy for a format.

  Prose formats can share the format-neutral content segmenter while supplying
  only the boundaries that must remain intact. Structured formats remain atomic
  so their document-level syntax is preserved.
  """
  def segmentation("markdown"), do: {:segmented, protected_delimiters: ["```", "~~~"]}
  def segmentation("text"), do: {:segmented, []}
  def segmentation(_format), do: :atomic
end
