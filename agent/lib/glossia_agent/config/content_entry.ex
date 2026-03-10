defmodule GlossiaAgent.Config.ContentEntry do
  @moduledoc """
  Content entry from a GLOSSIA.md `[[content]]` section.
  """

  @frontmatter_preserve "preserve"
  @frontmatter_translate "translate"

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
    :retries
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
          retries: non_neg_integer() | nil
        }

  def frontmatter_preserve, do: @frontmatter_preserve
  def frontmatter_translate, do: @frontmatter_translate

  @doc "Parse a content entry from a TOML map."
  @spec from_toml(map()) :: t()
  def from_toml(obj) when is_map(obj) do
    %__MODULE__{
      source: as_string(obj["source"]),
      path: as_string(obj["path"]),
      targets: as_string_list(obj["targets"]),
      output: as_string(obj["output"]),
      exclude: as_string_list(obj["exclude"]),
      preserve: as_string_list(obj["preserve"]),
      frontmatter: as_string(obj["frontmatter"]),
      prompt: as_string(obj["prompt"]),
      check_cmd: as_string(obj["check_cmd"]),
      check_cmds: as_string_map(obj["check_cmds"]),
      retries: as_int_or_nil(obj["retries"])
    }
  end

  @doc "Validate that a content entry has required fields."
  @spec valid?(t()) :: boolean()
  def valid?(%__MODULE__{} = entry) do
    source = String.trim(entry.source || entry.path || "")

    cond do
      source == "" -> false
      entry.targets != [] && String.trim(entry.output) == "" -> false
      entry.frontmatter not in ["", @frontmatter_preserve, @frontmatter_translate] -> false
      true -> true
    end
  end

  defp as_string(nil), do: ""
  defp as_string(v) when is_binary(v), do: v
  defp as_string(_), do: ""

  defp as_string_list(nil), do: []
  defp as_string_list(list) when is_list(list), do: Enum.filter(list, &is_binary/1)
  defp as_string_list(_), do: []

  defp as_string_map(nil), do: %{}

  defp as_string_map(map) when is_map(map) do
    Enum.into(map, %{}, fn
      {k, v} when is_binary(v) -> {to_string(k), v}
      {k, _} -> {to_string(k), ""}
    end)
  end

  defp as_string_map(_), do: %{}

  defp as_int_or_nil(nil), do: nil
  defp as_int_or_nil(v) when is_integer(v), do: v
  defp as_int_or_nil(v) when is_float(v), do: trunc(v)
  defp as_int_or_nil(_), do: nil
end
