defmodule GlossiaWeb.ChangelogController do
  use GlossiaWeb, :controller

  alias Glossia.Changelog
  alias GlossiaWeb.Feed

  def index(conn, _params) do
    render(conn, :index,
      entries: Changelog.all_entries(conn.assigns.locale),
      page_title: gettext("Changelog"),
      page_description: gettext("New updates and improvements to Glossia.")
    )
  end

  def feed(conn, _params) do
    changelog_path = locale_path(~p"/changelog")

    Feed.send(conn,
      title: "Glossia Changelog",
      description: gettext("New updates and improvements to Glossia."),
      path: changelog_path,
      items:
        Enum.map(Changelog.all_entries(conn.assigns.locale), fn entry ->
          %{
            title: entry.title,
            description: entry.summary,
            path: URI.to_string(%URI{path: changelog_path, fragment: entry.slug}),
            date: entry.date
          }
        end)
    )
  end
end
