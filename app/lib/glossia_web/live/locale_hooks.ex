defmodule GlossiaWeb.LocaleHooks do
  @moduledoc """
  Carries the request's locale into LiveView.

  Gettext keeps the locale in the process dictionary, and a LiveView runs in
  its own process, so the value resolved by `GlossiaWeb.Plugs.Locale` has to be
  handed over explicitly: `session/1` puts it in the live session and
  `on_mount/4` applies it to both the static render and the connected process.

  The signed-in user's own preference wins over the live session, which is
  frozen at the initial page load: without that, changing the language and
  navigating within the same live session would render in the old one until a
  full page reload. This hook therefore has to run *after* the hook that loads
  the current user.
  """

  import Phoenix.Component, only: [assign: 3]

  alias Glossia.I18n

  def session(conn) do
    %{"locale" => conn.assigns[:locale] || I18n.default_locale()}
  end

  def on_mount(:put_locale, _params, session, socket) do
    locale =
      user_locale(socket) || I18n.normalize(session["locale"]) || I18n.default_locale()

    Gettext.put_locale(GlossiaWeb.Gettext, locale)

    {:cont, assign(socket, :locale, locale)}
  end

  defp user_locale(socket) do
    case socket.assigns[:current_user] do
      %{locale: locale} -> I18n.normalize(locale)
      _no_user -> nil
    end
  end
end
