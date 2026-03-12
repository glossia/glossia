defmodule GlossiaAgent.Setup.Requirements do
  @moduledoc """
  Validates generated GLOSSIA.md content against deterministic setup requirements.
  """

  alias GlossiaAgent.Setup.FrameworkHints

  @spec validate_glossia(String.t(), [FrameworkHints.hint()]) :: :ok | {:error, String.t()}
  def validate_glossia(glossia_md, hints) do
    required_sources = FrameworkHints.required_sources(hints)

    if required_sources == [] do
      :ok
    else
      with {:ok, toml_text} <- extract_toml_frontmatter(glossia_md),
           {:ok, parsed} <- Toml.decode(toml_text),
           sources <- extract_sources(parsed),
           missing <- missing_required_sources(sources, required_sources) do
        if missing == [] do
          :ok
        else
          {:error,
           "generated GLOSSIA.md is missing required source patterns: #{Enum.join(missing, ", ")}"}
        end
      else
        {:error, reason} ->
          {:error, "failed to validate generated GLOSSIA.md requirements: #{reason}"}
      end
    end
  end

  defp extract_toml_frontmatter(glossia_md) do
    trimmed = String.trim(glossia_md)

    if String.starts_with?(trimmed, "+++") do
      rest = trimmed |> String.trim_leading("+++") |> String.trim_leading("\n")

      case :binary.match(rest, "+++") do
        {pos, _} ->
          toml_text = binary_part(rest, 0, pos) |> String.trim()
          {:ok, toml_text}

        :nomatch ->
          {:error, "missing closing +++ marker"}
      end
    else
      {:error, "missing opening +++ marker"}
    end
  end

  defp extract_sources(parsed) do
    parsed
    |> Map.get("content", [])
    |> Enum.flat_map(fn
      %{"source" => source} when is_binary(source) ->
        [String.trim(source)]

      _ ->
        []
    end)
    |> Enum.reject(&(&1 == ""))
  end

  defp missing_required_sources(sources, required_sources) do
    Enum.reject(required_sources, fn required ->
      Enum.any?(sources, &source_satisfies_requirement?(&1, required))
    end)
  end

  defp source_satisfies_requirement?(source, "priv/gettext/**/*.po") do
    String.contains?(source, "priv/gettext") && String.contains?(source, ".po")
  end

  defp source_satisfies_requirement?(source, required) do
    String.trim(source) == String.trim(required)
  end
end
