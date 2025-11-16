defmodule GlossiaWeb.API.TranslationController do
  use GlossiaWeb, :controller

  @doc """
  POST /api/translate
  Translates text from source language to target language using AI.

  Request body:
  {
    "text": "Hello, world!",
    "source_locale": "en",
    "target_locale": "es"
  }

  Response:
  {
    "translated_text": "¡Hola, mundo!",
    "source_locale": "en",
    "target_locale": "es"
  }
  """
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
