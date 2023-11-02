defmodule GlossiaWeb.Controllers.MarketingController do
  use GlossiaWeb.Helpers.Marketing, :controller

  def index(conn, _params) do
    conn
    |> render(:index)
  end

  def blog(conn, _params) do
    conn
    |> put_open_graph_metadata(%{
      title: "Blog",
      description:
        "Dive into the Glossia Blog, your go-to resource for insights on AI-powered translation, software localization, and innovative chat-based collaboration. Learn how Glossia revolutionizes language adaptability, fostering a global software community. Stay tuned for thought-provoking articles, tips, and more."
    })
    |> assign(:posts, Glossia.Marketing.Blog.all_posts())
    |> assign(:authors, Glossia.Marketing.Blog.all_authors())
    |> render(:blog)
  end

  def terms(conn, _params) do
    conn
    |> put_open_graph_metadata(%{
      title: "Terms of Service",
      description:
        "Glossia’s Terms of Service outline the terms and conditions of using Glossia’s services. By using Glossia’s services, you agree to the Terms of Service. Please read the Terms of Service carefully before using Glossia’s services."
    })
    |> render(:terms)
  end

  def privacy(conn, _params) do
    conn
    |> put_open_graph_metadata(%{
      title: "Privacy Policy",
      description:
        "Glossia’s Privacy Policy outlines how Glossia collects, uses, and shares your personal information. By using Glossia’s services, you agree to the Privacy Policy. Please read the Privacy Policy carefully before using Glossia’s services."
    })
    |> render(:privacy)
  end

  def blog_post(%{request_path: slug} = conn, params) do
    post = Glossia.Marketing.Blog.all_posts() |> Enum.find(&(&1.slug == slug))

    author =
      Glossia.Marketing.Blog.all_authors()
      |> Enum.find(&(&1.id == post.author_id))

    conn
    |> put_open_graph_metadata(%{
      title: post.title,
      description: post.description,
      keywords: post.tags
    })
    |> assign(:slug, slug)
    |> assign(:post, post)
    |> assign(:author, author)
    |> render(:blog_post)
  end

  def feed(conn, _params) do
    %{title: title, description: description, language: language, base_url: base_url} =
      Application.fetch_env!(:glossia, :open_graph_metadata)

    posts = Glossia.Marketing.Blog.all_posts()
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
