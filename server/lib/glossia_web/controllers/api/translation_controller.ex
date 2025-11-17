defmodule GlossiaWeb.API.TranslationController do
  use GlossiaWeb, :controller
  use OpenApiSpex.ControllerSpecs

  alias GlossiaWeb.Schemas.{TranslationRequest, TranslationResponse, ErrorResponse}

  tags ["Translation"]

  operation :translate,
    summary: "Translate content",
    description: """
    Translates content from a source locale to a target locale using AI.

    The API supports multiple formats:
    - **text** (default): Plain text translation
    - **json**: JSON translation files (preserves formatting)
    - **yaml**: YAML translation files (preserves formatting)
    - **xliff**: XLIFF localization files
    - **po**: Gettext PO files
    - **properties**: Java properties files
    - **arb**: Flutter ARB files
    - **strings**: iOS .strings files

    For structured formats, send the raw file content as a string.
    The translation preserves formatting, whitespace, and structure.
    """,
    request_body: {"Translation request", "application/json", TranslationRequest},
    responses: [
      ok: {"Translation successful", "application/json", TranslationResponse},
      bad_request: {"Invalid request", "application/json", ErrorResponse},
      unprocessable_entity: {"Validation error", "application/json", ErrorResponse},
      internal_server_error: {"Translation failed", "application/json", ErrorResponse}
    ]

  def translate(conn, %{
        "content" => content,
        "source_locale" => source_locale,
        "target_locale" => target_locale
      } = params) do
    format = Map.get(params, "format", "text")

    case translate_content(content, format, source_locale, target_locale) do
      {:ok, translated_content} ->
        json(conn, %{
          content: translated_content,
          format: format,
          source_locale: source_locale,
          target_locale: target_locale
        })

      {:error, reason} ->
        conn
        |> put_status(:internal_server_error)
        |> json(%{error: "Translation failed: #{inspect(reason)}"})
    end
  end

  defp translate_content(content, "text", source_locale, target_locale) do
    # For now, only "text" format is implemented
    # Other formats will be added incrementally
    Glossia.AI.Translator.translate(content, source_locale, target_locale)
  end

  defp translate_content(_content, format, _source_locale, _target_locale) do
    # Placeholder for future format implementations
    {:error, "Format '#{format}' is not yet supported. Currently supported: text"}
  end
end
