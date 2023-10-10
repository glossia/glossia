defmodule Glossia.Features.Marketing.Web.Controllers.MarketingController do
  use Glossia.Features.Marketing.Web.Helpers, :controller

  def index(conn, _params) do
    conn
    |> put_layout(false)
    |> render(:index)
  end

  def blog(conn, _params) do
    conn
    |> put_open_graph_metadata(%{
      title: "Blog",
      description:
        "Dive into the Glossia Blog, your go-to resource for insights on AI-powered translation, software localization, and innovative chat-based collaboration. Learn how Glossia revolutionizes language adaptability, fostering a global software community. Stay tuned for thought-provoking articles, tips, and more."
    })
    |> assign(:posts, Glossia.Features.Marketing.Core.Blog.all_posts())
    |> assign(:authors, Glossia.Features.Marketing.Core.Blog.all_authors())
    |> render(:blog)
  end

  def blog_post(%{request_path: slug} = conn, _params) do
    post = Glossia.Features.Marketing.Core.Blog.all_posts() |> Enum.find(&(&1.slug == slug))

    author =
      Glossia.Features.Marketing.Core.Blog.all_authors()
      |> Enum.find(&(&1.id == post.author_id))

    conn
    |> put_open_graph_metadata(%{
      title: post.title,
      description: post.description,
      keywords: post.tags
    })
    |> assign(:post, post)
    |> assign(:author, author)
    |> render(:blog_post)
  end

  def docs(conn, _params) do
    conn
    |> render(:docs)
  end

  def beta(conn, _params) do
    conn
    |> put_open_graph_metadata(%{
      title: "Beta Testing",
      description:
        "Join the future of automation today! Register on our page to become a beta tester for Glossia, the groundbreaking technology set to revolutionize your workflow. Sign up and be the first to experience Glossia’s innovative capabilities."
    })
    |> render(:beta)
  end

  def beta_added(conn, _params) do
    conn
    |> put_open_graph_metadata(%{
      title: "Successful Subscription to Glossia Beta Testing!",
      description:
        "Congratulations on your successful subscription to the Glossia Beta Testing! Your voyage into the future of automation begins soon. Stay tuned for launch details."
    })
    |> render(:beta_added)
  end

  def team(conn, _params) do
    conn
    |> put_open_graph_metadata(%{
      title: "Our Team",
      description:
        "Meet the team of innovative minds behind Glossia, the leading AI-powered localization tool transforming how businesses communicate across borders. Our diverse team of experts, dedicated to improving global communication, is committed to making localization more efficient and accurate than ever."
    })
    |> render(:team)
  end

  def about(conn, _params) do
    conn
    |> render(:about)
  end

  def feed(conn, _params) do
    %{title: title, description: description, language: language, base_url: base_url} =
      Application.fetch_env!(:glossia, :open_graph_metadata)

    posts = Glossia.Features.Marketing.Core.Blog.all_posts()
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
