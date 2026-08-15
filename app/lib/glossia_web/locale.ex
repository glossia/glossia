defmodule GlossiaWeb.Locale do
  @moduledoc """
  Helpers for linking between the localized versions of the marketing site.

  `locale_path/1` takes a path built with `~p` — so the route is still verified
  at compile time — and prefixes it with the locale of the current request,
  which Gettext already tracks per process. Templates therefore never have to
  thread a locale assign through to reach the right translation:

      <a href={locale_path(~p"/blog")}>{gettext("Blog")}</a>
  """

  alias Glossia.I18n

  def current, do: Gettext.get_locale(GlossiaWeb.Gettext)

  def locale_path(path), do: I18n.localize_path(current(), path)

  def locale_path(locale, path), do: I18n.localize_path(locale, path)
end
