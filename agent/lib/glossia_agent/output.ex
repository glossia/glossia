defmodule GlossiaAgent.Output do
  @moduledoc """
  Output path template expansion.
  Ported from agent/output.ts / cli/internal/glossia/output.go
  """

  @doc """
  Expand an output template with the given values.

  Supported placeholders: `{lang}`, `{relpath}`, `{basename}`, `{ext}`.
  """
  @spec expand(String.t(), map()) :: String.t()
  def expand(template, values) do
    template
    |> String.replace("{lang}", Map.get(values, :lang, ""))
    |> String.replace("{relpath}", normalize_slashes(Map.get(values, :rel_path, "")))
    |> String.replace("{basename}", Map.get(values, :basename, ""))
    |> String.replace("{ext}", Map.get(values, :ext, ""))
    |> normalize_slashes()
  end

  defp normalize_slashes(input) do
    input
    |> String.replace("\\", "/")
    |> String.replace(~r{//+}, "/")
  end
end
