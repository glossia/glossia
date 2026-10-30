defmodule GlossiaWeb.LegalController do
  use GlossiaWeb, :controller

  alias Glossia.Legal

  def terms(conn, params), do: show_document(conn, "terms", params)
  def privacy(conn, params), do: show_document(conn, "privacy", params)
  def cookies(conn, params), do: show_document(conn, "cookies", params)
  def acceptable_use(conn, params), do: show_document(conn, "acceptable-use", params)
  def imprint(conn, params), do: show_document(conn, "imprint", params)

  defp show_document(conn, document, %{"date" => date}) do
    locale = conn.assigns.locale
    version = Legal.get_version!(document, date, locale)
    all_versions = Legal.versions_for(document, locale)

    render(conn, :show,
      version: version,
      all_versions: all_versions,
      viewing_historical: version.date != hd(all_versions).date,
      page_title: version.title
    )
  end

  defp show_document(conn, document, _params) do
    locale = conn.assigns.locale
    version = Legal.latest_version!(document, locale)
    all_versions = Legal.versions_for(document, locale)

    render(conn, :show,
      version: version,
      all_versions: all_versions,
      viewing_historical: false,
      page_title: version.title
    )
  end
end
