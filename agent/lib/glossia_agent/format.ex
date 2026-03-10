defmodule GlossiaAgent.Format do
  @moduledoc """
  File format detection by extension.
  Ported from agent/format.ts / cli/internal/glossia/format.go
  """

  @type t :: :markdown | :json | :yaml | :po | :text

  @doc "Detect the format from a file path's extension."
  @spec detect(String.t()) :: t()
  def detect(file_path) do
    file_path
    |> Path.extname()
    |> String.trim_leading(".")
    |> String.downcase()
    |> do_detect()
  end

  defp do_detect("md"), do: :markdown
  defp do_detect("mdx"), do: :markdown
  defp do_detect("json"), do: :json
  defp do_detect("yaml"), do: :yaml
  defp do_detect("yml"), do: :yaml
  defp do_detect("po"), do: :po
  defp do_detect("pot"), do: :po
  defp do_detect(_), do: :text

  @doc "Returns true if the format is a structured data format (JSON, YAML, PO)."
  @spec structured?(t()) :: boolean()
  def structured?(:json), do: true
  def structured?(:yaml), do: true
  def structured?(:po), do: true
  def structured?(_), do: false

  @doc "Human-readable label for a format."
  @spec label(t()) :: String.t()
  def label(:json), do: "JSON"
  def label(:yaml), do: "YAML"
  def label(:po), do: "PO"
  def label(:markdown), do: "Markdown frontmatter"
  def label(:text), do: "text"
  def label(other), do: to_string(other)
end
