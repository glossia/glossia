defmodule GlossiaServerWeb.API.TranslationJSON do
  @doc """
  Renders translation result.
  """
  def translate(%{translated_text: translated_text, source_locale: source, target_locale: target}) do
    %{
      translated_text: translated_text,
      source_locale: source,
      target_locale: target
    }
  end

  @doc """
  Renders error responses.
  """
  def error(%{message: message}) do
    %{error: message}
  end
end
