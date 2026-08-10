defmodule GlossiaWeb.PageController do
  use GlossiaWeb, :controller

  alias Glossia.Blog

  def home(conn, _params) do
    case conn.assigns[:current_user] do
      %{account: %{handle: handle}} ->
        redirect(conn, to: ~p"/#{handle}")

      nil ->
        render(conn, :home,
          posts: Blog.recent_posts(),
          page_description:
            gettext(
              "Glossia is the open-source language OS where linguists and teams shape how your organization speaks across every language and surface."
            )
        )
    end
  end
end
