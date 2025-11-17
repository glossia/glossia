defmodule Glossia.AI.Translator do
  @moduledoc """
  Handles AI-powered translation using ReqLLM with Anthropic's Claude API.
  """

  @behaviour Glossia.AI.TranslatorBehaviour

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
    cond do
      String.trim(text) == "" ->
        {:error, :empty_text}

      source_locale == target_locale ->
        {:ok, text}

      true ->
        call_llm(text, source_locale, target_locale)
    end
  end

  defp call_llm(text, source_locale, target_locale) do
    prompt = build_translation_prompt(text, source_locale, target_locale)
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

  defp build_translation_prompt(text, source_locale, target_locale) do
    """
    Translate the following text from #{source_locale} to #{target_locale}.
    Preserve formatting, variables, and placeholders exactly as they appear.
    Only respond with the translated text, nothing else.

    Text to translate:
    #{text}
    """
  end
end
