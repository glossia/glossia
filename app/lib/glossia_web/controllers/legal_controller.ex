defmodule GlossiaWeb.LegalController do
  use GlossiaWeb, :controller

  alias Glossia.Legal

  def terms(conn, params), do: show_document(conn, "terms", params)
  def privacy(conn, params), do: show_document(conn, "privacy", params)
  def cookies(conn, params), do: show_document(conn, "cookies", params)

  defp show_document(conn, document, %{"date" => date}) do
    version = Legal.get_version!(document, date)
    all_versions = Legal.versions_for(document)

    render(conn, :show,
      version: version,
      all_versions: all_versions,
      viewing_historical: true,
      page_title: version.title
    )
  end

  defp show_document(conn, document, _params) do
    version = Legal.latest_version!(document)
    all_versions = Legal.versions_for(document)

    render(conn, :show,
      version: version,
      all_versions: all_versions,
      viewing_historical: false,
      page_title: version.title
    )
  end
end
