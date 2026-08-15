defmodule GlossiaWeb.PageController do
  use GlossiaWeb, :controller

  alias Glossia.Blog

  def home(conn, _params) do
    case conn.assigns[:current_user] do
      %{account: %{handle: handle}} ->
        account_path = ~p"/#{handle}"

        # An account created before the locale prefixes existed can have a
        # handle that now reads as one, e.g. `/es`. Its page is shadowed by the
        # Spanish home page, and redirecting there from that very URL would
        # loop forever, so those visitors get the marketing page instead.
        if account_path == conn.request_path do
          render_home(conn)
        else
          redirect(conn, to: account_path)
        end

      _guest ->
        render_home(conn)
    end
  end

  defp render_home(conn) do
    render(conn, :home,
      posts: Blog.recent_posts(3, conn.assigns.locale),
      page_description:
        gettext(
          "Glossia is the open-source language OS where linguists and teams shape how your organization speaks across every language and surface."
        )
    )
  end
end
