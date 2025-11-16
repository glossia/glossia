defmodule GlossiaWeb.API.TranslationController do
  use GlossiaWeb, :controller
  use OpenApiSpex.ControllerSpecs

  alias GlossiaWeb.Schemas.{TranslationRequest, TranslationResponse, ErrorResponse}

  tags ["Translation"]

  operation :translate,
    summary: "Translate text",
    description: """
    Translates text from a source locale to a target locale using AI.

    The translation preserves formatting, variables, and placeholders.
    """,
    request_body: {"Translation request", "application/json", TranslationRequest},
    responses: [
      ok: {"Translation successful", "application/json", TranslationResponse},
      bad_request: {"Invalid request", "application/json", ErrorResponse},
      internal_server_error: {"Translation failed", "application/json", ErrorResponse}
    ]

  def translate(conn, %{
        "text" => text,
        "source_locale" => source_locale,
        "target_locale" => target_locale
      }) do
    case Glossia.AI.Translator.translate(text, source_locale, target_locale) do
      {:ok, translated_text} ->
        json(conn, %{
          translated_text: translated_text,
          source_locale: source_locale,
          target_locale: target_locale
        })

      {:error, reason} ->
        conn
        |> put_status(:internal_server_error)
        |> json(%{error: "Translation failed: #{inspect(reason)}"})
    end
  end

  def translate(conn, _params) do
    conn
    |> put_status(:bad_request)
    |> json(%{error: "Missing required parameters: text, source_locale, target_locale"})
  end
end
