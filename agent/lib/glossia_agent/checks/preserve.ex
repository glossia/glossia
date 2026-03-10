defmodule GlossiaAgent.Checks.Preserve do
  @moduledoc """
  Validates that preserved tokens (code blocks, inline code, URLs, placeholders)
  from the source survive in the translated output.
  """

  @default_preserve ["code_blocks", "inline_code", "urls", "placeholders"]

  @doc "Resolve which preservation kinds to check."
  @spec resolve_kinds([String.t()]) :: [String.t()]
  def resolve_kinds([]), do: @default_preserve

  def resolve_kinds(kinds) do
    if Enum.any?(kinds, &(String.downcase(String.trim(&1)) == "none")) do
      []
    else
      kinds
      |> Enum.map(&String.downcase(String.trim(&1)))
      |> Enum.reject(&(&1 == ""))
    end
  end

  @doc "Validate that preserved tokens exist in the output. Returns nil if valid."
  @spec validate(String.t(), String.t(), [String.t()]) :: String.t() | nil
  def validate(output, source, preserve_kinds) do
    tokens = extract_preservables(source, preserve_kinds)

    missing =
      tokens
      |> Enum.reject(&String.contains?(output, &1))
      |> Enum.take(5)

    if missing == [] do
      nil
    else
      "preserved tokens missing from output: #{Jason.encode!(missing)}"
    end
  end

  @doc false
  def extract_preservables(source, preserve_kinds) do
    {tokens, working} =
      if "code_blocks" in preserve_kinds do
        extract_code_blocks(source)
      else
        {[], source}
      end

    tokens =
      if "inline_code" in preserve_kinds do
        inline = Regex.scan(~r/`[^`\n]+`/, working) |> Enum.map(&hd/1)
        tokens ++ inline
      else
        tokens
      end

    tokens =
      if "urls" in preserve_kinds do
        urls = Regex.scan(~r{https?://[^\s)"'<>]+}, working) |> Enum.map(&hd/1)
        tokens ++ urls
      else
        tokens
      end

    tokens =
      if "placeholders" in preserve_kinds do
        placeholders = Regex.scan(~r/\{[^\s{}]+\}/, working) |> Enum.map(&hd/1)
        tokens ++ placeholders
      else
        tokens
      end

    tokens |> Enum.uniq()
  end

  defp extract_code_blocks(source) do
    do_extract_code_blocks(source, 0, [], "")
  end

  defp do_extract_code_blocks(source, i, blocks, stripped) when i >= byte_size(source) do
    {blocks, stripped}
  end

  defp do_extract_code_blocks(source, i, blocks, stripped) do
    case :binary.match(source, "```", scope: {i, byte_size(source) - i}) do
      {start, _} ->
        stripped = stripped <> binary_part(source, i, start - i)

        case :binary.match(source, "```", scope: {start + 3, byte_size(source) - start - 3}) do
          {end_pos, _} ->
            block_end = end_pos + 3
            block = binary_part(source, start, block_end - start)
            do_extract_code_blocks(source, block_end, blocks ++ [block], stripped)

          :nomatch ->
            {blocks, stripped <> binary_part(source, start, byte_size(source) - start)}
        end

      :nomatch ->
        {blocks, stripped <> binary_part(source, i, byte_size(source) - i)}
    end
  end
end
