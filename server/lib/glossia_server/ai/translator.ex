defmodule GlossiaServer.AI.Translator do
  @moduledoc """
  Handles AI-powered translation using Anthropic's Claude API.
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
        call_anthropic_api(text, source_locale, target_locale)
    end
  end

  defp call_anthropic_api(text, source_locale, target_locale) do
    api_key = get_api_key()

    if is_nil(api_key) do
      Logger.error("ANTHROPIC_API_KEY not configured")
      {:error, :api_key_not_configured}
    else
      prompt = build_translation_prompt(text, source_locale, target_locale)

      case make_api_request(api_key, prompt) do
        {:ok, translated_text} ->
          {:ok, translated_text}

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

  defp make_api_request(api_key, prompt) do
    url = "https://api.anthropic.com/v1/messages"

    headers = [
      {"x-api-key", api_key},
      {"anthropic-version", "2023-06-01"},
      {"content-type", "application/json"}
    ]

    body = %{
      model: "claude-sonnet-4-20250514",
      max_tokens: 4096,
      messages: [
        %{
          role: "user",
          content: prompt
        }
      ]
    }

    case Req.post(url, headers: headers, json: body) do
      {:ok, %{status: 200, body: response_body}} ->
        extract_translation(response_body)

      {:ok, %{status: status, body: body}} ->
        Logger.error("Anthropic API returned status #{status}: #{inspect(body)}")
        {:error, {:api_error, status, body}}

      {:error, reason} ->
        {:error, {:request_failed, reason}}
    end
  end

  defp extract_translation(%{"content" => [%{"text" => text} | _]}) do
    {:ok, String.trim(text)}
  end

  defp extract_translation(response) do
    Logger.error("Unexpected API response format: #{inspect(response)}")
    {:error, :unexpected_response_format}
  end

  defp get_api_key do
    Application.get_env(:glossia_server, :anthropic_api_key) ||
      System.get_env("ANTHROPIC_API_KEY")
  end
end
