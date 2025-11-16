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
    api_key = get_api_key()

    if is_nil(api_key) do
      Logger.error("ANTHROPIC_API_KEY not configured")
      {:error, :api_key_not_configured}
    else
      # Set the API key for ReqLLM
      ReqLLM.put_key(:anthropic_api_key, api_key)

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

  defp get_api_key do
    Application.get_env(:glossia, :anthropic_api_key) ||
      System.get_env("ANTHROPIC_API_KEY")
  end
end
