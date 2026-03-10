defmodule GlossiaAgent.Setup.Extractor do
  @moduledoc """
  Extracts and validates GLOSSIA.md content from LLM output.
  """

  @doc """
  Extract GLOSSIA.md content from LLM response text.

  Handles several cases:
  - Clean output starting with +++
  - Output wrapped in markdown code fences
  - Output with preamble text before +++

  Returns `{:ok, content}` or `{:error, reason}`.
  """
  @spec extract(String.t()) :: {:ok, String.t()} | {:error, String.t()}
  def extract(text) do
    trimmed = String.trim(text)

    cond do
      String.starts_with?(trimmed, "+++") ->
        validate_structure(trimmed)

      true ->
        case extract_from_fences(trimmed) do
          {:ok, content} ->
            validate_structure(content)

          :not_found ->
            case extract_from_markers(trimmed) do
              {:ok, content} -> validate_structure(content)
              :not_found -> {:error, "no GLOSSIA.md content found in LLM output"}
            end
        end
    end
  end

  @doc """
  Validate that a GLOSSIA.md string has proper structure:
  - Starts with +++
  - Has a closing +++
  - Contains at least one [[content]] entry
  - TOML frontmatter parses successfully
  """
  @spec validate_structure(String.t()) :: {:ok, String.t()} | {:error, String.t()}
  def validate_structure(content) do
    trimmed = String.trim(content)

    cond do
      !String.starts_with?(trimmed, "+++") ->
        {:error, "GLOSSIA.md must start with +++"}

      true ->
        case split_frontmatter(trimmed) do
          {:ok, toml_text, free_text} ->
            case Toml.decode(toml_text) do
              {:ok, parsed} ->
                content_entries = parsed["content"] || []

                if is_list(content_entries) && content_entries != [] do
                  # Reconstruct clean content
                  clean =
                    if String.trim(free_text) != "" do
                      "+++\n#{toml_text}\n+++\n\n#{String.trim(free_text)}\n"
                    else
                      "+++\n#{toml_text}\n+++\n"
                    end

                  {:ok, clean}
                else
                  {:error, "GLOSSIA.md must contain at least one [[content]] entry"}
                end

              {:error, error} ->
                {:error, "GLOSSIA.md TOML parse error: #{inspect(error)}"}
            end

          {:error, reason} ->
            {:error, reason}
        end
    end
  end

  defp split_frontmatter(content) do
    # Remove leading +++
    rest = content |> String.trim_leading("+++") |> String.trim_leading("\n")

    case :binary.match(rest, "+++") do
      {pos, _len} ->
        toml_text = binary_part(rest, 0, pos) |> String.trim()
        free_text = binary_part(rest, pos + 3, byte_size(rest) - pos - 3) |> String.trim()
        {:ok, toml_text, free_text}

      :nomatch ->
        {:error, "GLOSSIA.md missing closing +++ marker"}
    end
  end

  defp extract_from_fences(text) do
    # Match ```toml ... ``` or ``` ... ```
    case Regex.run(~r/```(?:toml)?\s*\n(\+\+\+[\s\S]*?\+\+\+[\s\S]*?)```/m, text) do
      [_, content] -> {:ok, String.trim(content)}
      _ -> :not_found
    end
  end

  defp extract_from_markers(text) do
    # Find first +++ and extract from there
    case :binary.match(text, "+++") do
      {pos, _} ->
        from_marker = binary_part(text, pos, byte_size(text) - pos)
        # Check it has a closing +++
        rest = from_marker |> String.trim_leading("+++") |> String.trim_leading("\n")

        case :binary.match(rest, "+++") do
          {_, _} -> {:ok, String.trim(from_marker)}
          :nomatch -> :not_found
        end

      :nomatch ->
        :not_found
    end
  end
end
