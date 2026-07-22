defmodule GlossiaWeb.Plugs.Locale do
  @moduledoc """
  Reads the Accept-Language header and sets the Gettext locale for the request.

  English (`en`) is the default/fallback locale, so missing target translations
  continue to render the original source strings.
  """

  import Plug.Conn

  @default_locale "en"

  @locales %{
    "en" => "en",
    "es" => "es",
    "fr" => "fr",
    "de" => "de",
    "ja" => "ja",
    "ko" => "ko",
    "zh" => "zh-Hans",
    "zh-hans" => "zh-Hans",
    "zh-cn" => "zh-Hans",
    "pt" => "pt-BR",
    "pt-br" => "pt-BR"
  }

  def init(opts), do: opts

  def call(conn, _opts) do
    case accepted_locale(conn) do
      nil ->
        conn

      locale when locale != @default_locale ->
        Gettext.put_locale(GlossiaWeb.Gettext, locale)
        conn

      _ ->
        conn
    end
  end

  defp accepted_locale(conn) do
    case get_req_header(conn, "accept-language") do
      [] ->
        @default_locale

      [languages | _] ->
        languages
        |> String.split(",")
        |> Enum.map(&normalize_language/1)
        |> Enum.find(&(Map.has_key?(@locales, &1)))
        |> then(&Map.get(@locales, &1, @default_locale))
    end
  end

  defp normalize_language(language) do
    language
    |> String.split(";")
    |> List.first()
    |> String.trim()
    |> String.downcase()
  end
end
