defmodule Glossia.Web.MarketingController do
  use Glossia.Web, :controller

  def index(conn, _params) do
    if conn.assigns[:current_user] do
      conn
      |> put_root_layout(html: {Glossia.Web.AppLayouts, :root})
      |> render(:index_app)
    else
      conn
      |> put_root_layout(html: {Glossia.Web.MarketingLayouts, :root})
      |> put_layout(false)
      |> render(:index)
    end
  end

  def blog(conn, _params) do
    dbg(Glossia.Blog.all_authors())

    conn
    |> assign(:posts, Glossia.Blog.all_posts())
    |> assign(:authors, Glossia.Blog.all_authors())
    |> put_root_layout(html: {Glossia.Web.MarketingLayouts, :root})
    |> put_layout(html: {Glossia.Web.MarketingLayouts, :base})
    |> render(:blog)
  end

  def blog_post(%{request_path: slug} = conn, _params) do
    post = Glossia.Blog.all_posts() |> Enum.find(&(&1.slug == slug))

    author =
      Glossia.Blog.all_authors()
      |> Enum.find(&(&1.id == String.to_atom(post.author_id)))

    conn
    |> assign(:post, post)
    |> assign(:author, author)
    |> put_root_layout(html: {Glossia.Web.MarketingLayouts, :root})
    |> put_layout(html: {Glossia.Web.MarketingLayouts, :base})
    |> render(:blog_post)
  end

  def docs(conn, %{"id" => []}) do
    conn
    |> put_root_layout(html: {Glossia.Web.MarketingLayouts, :root})
    |> put_layout(html: {Glossia.Web.MarketingLayouts, :base})
    |> render(:docs)
  end

  def docs(conn, _params) do
    conn
    |> put_root_layout(html: {Glossia.Web.MarketingLayouts, :root})
    |> put_layout(html: {Glossia.Web.MarketingLayouts, :base})
    |> render(:docs)
  end

  def beta(conn, _params) do
    conn
    |> put_root_layout(html: {Glossia.Web.MarketingLayouts, :root})
    |> put_layout(html: {Glossia.Web.MarketingLayouts, :base})
    |> render(:beta)
  end

  def beta_added(conn, _params) do
    conn
    |> put_root_layout(html: {Glossia.Web.MarketingLayouts, :root})
    |> put_layout(html: {Glossia.Web.MarketingLayouts, :base})
    |> render(:beta_added)
  end

  def changelog(conn, _params) do
    conn
    |> assign(:updates, Glossia.Changelog.all_updates())
    |> put_root_layout(html: {Glossia.Web.MarketingLayouts, :root})
    |> put_layout(html: {Glossia.Web.MarketingLayouts, :base})
    |> render(:changelog)
  end

  def team(conn, _params) do
    conn
    |> put_root_layout(html: {Glossia.Web.MarketingLayouts, :root})
    |> put_layout(html: {Glossia.Web.MarketingLayouts, :base})
    |> render(:team)
  end

  def about(conn, _params) do
    conn
    |> put_root_layout(html: {Glossia.Web.MarketingLayouts, :root})
    |> put_layout(html: {Glossia.Web.MarketingLayouts, :base})
    |> render(:about)
  end

  def feed(conn, _params) do
    %{title: title, description: description, language: language, base_url: base_url} =
      Application.fetch_env!(:glossia, :seo_metadata)

    posts = Glossia.Blog.all_posts()
    last_build_date = posts |> List.first() |> Map.get(:date)

    conn
    |> put_resp_content_type("text/xml")
    |> render("feed.xml",
      layout: false,
      posts: posts,
      title: title,
      description: description,
      language: language,
      base_url: base_url,
      last_build_date: last_build_date
    )
  end
end