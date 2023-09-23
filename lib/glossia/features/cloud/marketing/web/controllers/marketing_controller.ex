defmodule Glossia.Features.Cloud.Marketing.Web.Controllers.MarketingController do
  use Glossia.Features.Cloud.Marketing.Web.Helpers, :controller

  def index(conn, _params) do
    conn
    |> put_layout(false)
    |> render(:index)
  end

  def blog(conn, _params) do
    conn
    |> assign(:posts, Glossia.Features.Cloud.Marketing.Core.Blog.all_posts())
    |> assign(:authors, Glossia.Features.Cloud.Marketing.Core.Blog.all_authors())
    |> render(:blog)
  end

  def blog_post(%{request_path: slug} = conn, _params) do
    post = Glossia.Features.Cloud.Marketing.Core.Blog.all_posts() |> Enum.find(&(&1.slug == slug))

    author =
      Glossia.Features.Cloud.Marketing.Core.Blog.all_authors()
      |> Enum.find(&(&1.id == String.to_atom(post.author_id)))

    conn
    |> assign(:post, post)
    |> assign(:author, author)
    |> render(:blog_post)
  end

  def docs(conn, %{"id" => []}) do
    conn
    |> render(:docs)
  end

  def docs(conn, _params) do
    conn
    |> render(:docs)
  end

  def beta(conn, _params) do
    conn
    |> render(:beta)
  end

  def beta_added(conn, _params) do
    conn
    |> render(:beta_added)
  end

  def team(conn, _params) do
    conn
    |> render(:team)
  end

  def about(conn, _params) do
    conn
    |> render(:about)
  end

  def feed(conn, _params) do
    %{title: title, description: description, language: language, base_url: base_url} =
      Application.fetch_env!(:glossia, :seo_metadata)

    posts = Glossia.Features.Cloud.Marketing.Core.Blog.all_posts()
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
