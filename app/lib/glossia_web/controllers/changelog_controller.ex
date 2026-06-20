defmodule GlossiaWeb.ChangelogController do
  use GlossiaWeb, :controller

  alias Glossia.Changelog
  alias GlossiaWeb.Feed

  def index(conn, _params) do
    render(conn, :index,
      entries: Changelog.all_entries(),
      page_title: gettext("Changelog"),
      page_description: gettext("New updates and improvements to Glossia.")
    )
  end

  def feed(conn, _params) do
    Feed.send(conn,
      title: "Glossia Changelog",
      description: "New updates and improvements to Glossia.",
      path: "/changelog",
      items:
        Enum.map(Changelog.all_entries(), fn entry ->
          %{
            title: entry.title,
            description: entry.summary,
            path: "/changelog##{entry.slug}",
            date: entry.date
          }
        end)
    )
  end
end
