defmodule Glossia.AI.Translator do
  @moduledoc """
  Handles AI-powered translation using ReqLLM with Anthropic's Claude API.
  """

  require Logger

  @doc """
  Translates text from source locale to target locale using AI.

  ## Examples

      iex> translate("Hello, world!", "en", "es")
      {:ok, "¡Hola, mundo!"}

      iex> translate("", "en", "es")
      {:error, :empty_text}
  """
  def translate(text, source_locale, target_locale) when is_binary(text) do
    translate_with_instructions(text, source_locale, target_locale, nil)
  end

  @doc """
  Translates content with format-specific instructions.

  This is used for translating entire files while preserving their structure.

  ## Parameters
    - content: The full file content to translate
    - source_locale: Source language code
    - target_locale: Target language code
    - format_instructions: Optional format-specific instructions for the LLM

  ## Examples

      iex> instructions = "Preserve all FTL syntax including keys, comments, and attributes"
      iex> translate_with_instructions(ftl_content, "en", "es", instructions)
      {:ok, translated_ftl_content}
  """
  def translate_with_instructions(content, source_locale, target_locale, format_instructions \\ nil)
      when is_binary(content) do
    cond do
      String.trim(content) == "" ->
        {:error, :empty_text}

      source_locale == target_locale ->
        {:ok, content}

      true ->
        call_llm(content, source_locale, target_locale, format_instructions)
    end
  end

  defp call_llm(text, source_locale, target_locale, format_instructions \\ nil) do
    prompt = build_translation_prompt(text, source_locale, target_locale, format_instructions)
    model = "anthropic:claude-sonnet-4-20250514"

    case ReqLLM.generate_text(model, prompt, temperature: 0.3) do
      {:ok, response} ->
        Logger.debug("Translation successful. Tokens: #{response.usage.total_tokens}, Cost: $#{response.usage.total_cost}")
        {:ok, String.trim(response.text)}

      {:error, reason} ->
        Logger.error("Translation API error: #{inspect(reason)}")
        {:error, reason}
    end
  end

  defp build_translation_prompt(text, source_locale, target_locale, format_instructions \\ nil) do
    format_section =
      if format_instructions do
        "\n\nFormat-specific requirements:\n#{format_instructions}\n"
      else
        ""
      end

    """
    Translate the following text from #{source_locale} to #{target_locale}.
    Preserve formatting, variables, and placeholders exactly as they appear.#{format_section}
    Only respond with the translated text, nothing else.

    Text to translate:
    #{text}
    """
  end
end
