defmodule GlossiaWeb.PageController do
  use GlossiaWeb, :controller

  alias Glossia.Blog

  def interest(conn, _params) do
    render(conn, :interest,
      page_title: gettext("Get started"),
      page_description:
        gettext("Tell us what you want to build with Glossia, or join the community.")
    )
  end

  def home(conn, _params) do
    case conn.assigns[:current_user] do
      %{account: %{has_access: true, handle: handle}} ->
        redirect(conn, to: ~p"/#{handle}")

      %{} ->
        redirect(conn, to: ~p"/interest")

      nil ->
        render(conn, :home,
          posts: Blog.recent_posts(),
          page_description:
            gettext(
              "Glossia captures your linguistic preferences in one place so linguists and teams can shape how your organization speaks across every language and surface."
            )
        )
    end
  end
end
