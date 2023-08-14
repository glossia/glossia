defmodule GlossiaWeb.MarketingController do
  use GlossiaWeb, :controller

  def index(conn, _params) do
    if conn.assigns[:current_user] do
      conn
      |> put_root_layout(html: {GlossiaWeb.AppLayouts, :root})
      |> render(:index_app)
    else
      conn
      |> put_root_layout(html: {GlossiaWeb.MarketingLayouts, :root})
      |> put_layout(false)
      |> render(:index_marketing)
    end
  end

  def blog(conn, _params) do
    dbg(Glossia.Blog.all_authors())

    conn
    |> assign(:posts, Glossia.Blog.all_posts())
    |> assign(:authors, Glossia.Blog.all_authors())
    |> put_root_layout(html: {GlossiaWeb.MarketingLayouts, :root})
    |> put_layout(html: {GlossiaWeb.MarketingLayouts, :base})
    |> render(:blog_marketing)
  end

  def blog_post(%{request_path: slug} = conn, _params) do
    post = Glossia.Blog.all_posts() |> Enum.find(&(&1.slug == slug))

    author =
      Glossia.Blog.all_authors()
      |> Enum.find(&(&1.id == String.to_atom(post.author_id)))

    conn
    |> assign(:post, post)
    |> assign(:author, author)
    |> put_root_layout(html: {GlossiaWeb.MarketingLayouts, :root})
    |> put_layout(html: {GlossiaWeb.MarketingLayouts, :base})
    |> render(:blog_post_marketing)
  end

  def docs(conn, %{"id" => []}) do
    conn
    |> put_root_layout(html: {GlossiaWeb.MarketingLayouts, :root})
    |> put_layout(html: {GlossiaWeb.MarketingLayouts, :base})
    |> render(:docs_marketing)
  end

  def docs(conn, params) do
    conn
    |> put_root_layout(html: {GlossiaWeb.MarketingLayouts, :root})
    |> put_layout(html: {GlossiaWeb.MarketingLayouts, :base})
    |> render(:docs_marketing)
  end

  def beta(conn, _params) do
    conn
    |> put_root_layout(html: {GlossiaWeb.MarketingLayouts, :root})
    |> put_layout(html: {GlossiaWeb.MarketingLayouts, :base})
    |> render(:beta_marketing)
  end

  def beta_added(conn, _params) do
    conn
    |> put_root_layout(html: {GlossiaWeb.MarketingLayouts, :root})
    |> put_layout(html: {GlossiaWeb.MarketingLayouts, :base})
    |> render(:beta_added_marketing)
  end

  def changelog(conn, _params) do
    conn
    |> assign(:updates, Glossia.Changelog.all_updates())
    |> put_root_layout(html: {GlossiaWeb.MarketingLayouts, :root})
    |> put_layout(html: {GlossiaWeb.MarketingLayouts, :base})
    |> render(:changelog_marketing)
  end

  def team(conn, _params) do
    conn
    |> put_root_layout(html: {GlossiaWeb.MarketingLayouts, :root})
    |> put_layout(html: {GlossiaWeb.MarketingLayouts, :base})
    |> render(:team_marketing)
  end

  def about(conn, _params) do
    conn
    |> put_root_layout(html: {GlossiaWeb.MarketingLayouts, :root})
    |> put_layout(html: {GlossiaWeb.MarketingLayouts, :base})
    |> render(:about_marketing)
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
