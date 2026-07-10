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

  @doc "All supported format strings."
  def formats, do: @formats

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

  @doc "Whether a format has machine-parseable structure (json/yaml/po)."
  def structured?(format), do: format in @structured
end
