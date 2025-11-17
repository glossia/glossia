defmodule GlossiaWeb.API.TranslationController do
  use GlossiaWeb, :controller
  use OpenApiSpex.ControllerSpecs

  alias GlossiaWeb.Schemas.{TranslationRequest, TranslationResponse, ErrorResponse}
  alias Glossia.Formats.{TextHandler, JsonHandler}

  tags ["Translation"]

  operation :translate,
    summary: "Translate content",
    description: """
    Translates content from a source locale to a target locale using AI.

    The API supports multiple formats:
    - **text** (default): Plain text translation
    - **json**: JSON translation files (preserves formatting and structure)
    - **yaml**: YAML translation files (coming soon)
    - **xliff**: XLIFF localization files (coming soon)
    - **po**: Gettext PO files (coming soon)
    - **properties**: Java properties files (coming soon)
    - **arb**: Flutter ARB files (coming soon)
    - **strings**: iOS .strings files (coming soon)

    For structured formats, send the raw file content as a string.
    The translation preserves formatting, whitespace, and structure to minimize diffs.
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

    with {:ok, handler} <- get_format_handler(format),
         :ok <- handler.validate(content),
         {:ok, translated_content} <- handler.translate(content, source_locale, target_locale),
         :ok <- handler.validate(translated_content) do
      json(conn, %{
        content: translated_content,
        format: format,
        source_locale: source_locale,
        target_locale: target_locale
      })
    else
      {:error, :unsupported_format} ->
        conn
        |> put_status(:bad_request)
        |> json(%{error: "Format '#{format}' is not yet supported. Currently supported: text, json"})

      {:error, reason} ->
        conn
        |> put_status(:internal_server_error)
        |> json(%{error: "Translation failed: #{inspect(reason)}"})
    end
  end

  defp get_format_handler("text"), do: {:ok, TextHandler}
  defp get_format_handler("json"), do: {:ok, JsonHandler}
  defp get_format_handler(_), do: {:error, :unsupported_format}
end
