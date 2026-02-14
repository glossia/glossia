defmodule GlossiaWeb.PageController do
  use GlossiaWeb, :controller

  alias Glossia.Blog

  def home(conn, _params) do
    posts = Blog.recent_posts(2)
    render(conn, :home, posts: posts, page_title: gettext("Home"))
  end
end
