defmodule GlossiaWeb.Plugs.Locale do
  @moduledoc """
  Resolves the locale for the request and makes it available to Gettext.

  Resolution order, most specific first:

    1. the locale encoded in the URL (marketing routes under `/es`, `/ja`, ...),
       which the router puts in `conn.assigns.url_locale`
    2. the signed-in user's preference, which is the language they picked for
       their account and therefore outranks any device-local choice
    3. the `glossia_locale` cookie, written when a visitor picks a language
       explicitly
    4. the browser's `Accept-Language` header
    5. English

  This plug never redirects: `GlossiaWeb.Plugs.MarketingLocale` owns that, so
  the dashboard and the API keep serving whatever URL was requested.
  """

  import Plug.Conn

  alias Glossia.I18n

  @cookie "glossia_locale"
  # Long-lived: an explicit language choice should outlive a browser session.
  @cookie_max_age 365 * 24 * 60 * 60

  def cookie, do: @cookie

  def cookie_max_age, do: @cookie_max_age

  def init(opts), do: opts

  def call(conn, _opts) do
    locale = resolve(conn)
    Gettext.put_locale(GlossiaWeb.Gettext, locale)

    assign(conn, :locale, locale)
  end

  @doc """
  The locale for the request, ignoring any locale encoded in the URL. This is
  what an unprefixed marketing URL would redirect to.
  """
  def preferred_locale(conn) do
    user_locale(conn) || cookie_locale(conn) || header_locale(conn) || I18n.default_locale()
  end

  defp resolve(conn) do
    conn.assigns[:url_locale] || preferred_locale(conn)
  end

  defp cookie_locale(conn) do
    conn = fetch_cookies(conn)

    conn.cookies
    |> Map.get(@cookie)
    |> I18n.normalize()
  end

  defp user_locale(%{assigns: %{current_user: %{locale: locale}}}), do: I18n.normalize(locale)
  defp user_locale(_conn), do: nil

  defp header_locale(conn) do
    conn
    |> get_req_header("accept-language")
    |> List.first()
    |> I18n.from_accept_language()
  end
end
