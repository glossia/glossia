defmodule GlossiaWeb.Controllers.MarketingController do
  use GlossiaWeb.Helpers.Marketing, :controller

  def index(conn, _params) do
    conn
    |> render(:index)
  end

  @spec blog(
          %{
            :__struct__ => Phoenix.LiveView.Socket | Plug.Conn,
            :assigns => Phoenix.LiveView.Socket.assigns_not_in_socket() | map(),
            :private => map(),
            optional(:adapter) => {atom(), any()},
            optional(:body_params) => %{
              optional(:__struct__) => Plug.Conn.Unfetched,
              optional(:aspect) => atom(),
              optional(binary()) => any()
            },
            optional(:cookies) => %{
              optional(:__struct__) => Plug.Conn.Unfetched,
              optional(:aspect) => atom(),
              optional(binary()) => any()
            },
            optional(:endpoint) => atom(),
            optional(:fingerprints) => {nil | binary(), map()},
            optional(:halted) => boolean(),
            optional(:host) => binary(),
            optional(:host_uri) => :not_mounted_at_router | URI.t(),
            optional(:id) => binary(),
            optional(:method) => binary(),
            optional(:owner) => pid(),
            optional(:params) => %{
              optional(:__struct__) => Plug.Conn.Unfetched,
              optional(:aspect) => atom(),
              optional(binary()) => any()
            },
            optional(:parent_pid) => nil | pid(),
            optional(:path_info) => [binary()],
            optional(:path_params) => %{
              optional(binary()) =>
                binary()
                | [binary() | list() | map()]
                | %{optional(binary()) => binary() | list() | map()}
            },
            optional(:port) => char(),
            optional(:query_params) => %{
              optional(:__struct__) => Plug.Conn.Unfetched,
              optional(:aspect) => atom(),
              optional(binary()) =>
                binary()
                | [binary() | list() | map()]
                | %{optional(binary()) => binary() | list() | map()}
            },
            optional(:query_string) => binary(),
            optional(:redirected) => nil | tuple(),
            optional(:remote_ip) =>
              {byte(), byte(), byte(), byte()}
              | {char(), char(), char(), char(), char(), char(), char(), char()},
            optional(:req_cookies) => %{
              optional(:__struct__) => Plug.Conn.Unfetched,
              optional(:aspect) => atom(),
              optional(binary()) => binary()
            },
            optional(:req_headers) => [{binary(), binary()}],
            optional(:request_path) => binary(),
            optional(:resp_body) =>
              nil
              | binary()
              | maybe_improper_list(
                  binary() | maybe_improper_list(any(), binary() | []) | byte(),
                  binary() | []
                ),
            optional(:resp_cookies) => %{optional(binary()) => map()},
            optional(:resp_headers) => [{binary(), binary()}],
            optional(:root_pid) => pid(),
            optional(:router) => atom(),
            optional(:scheme) => :http | :https,
            optional(:script_name) => [binary()],
            optional(:secret_key_base) => nil | binary(),
            optional(:state) =>
              :chunked | :file | :sent | :set | :set_chunked | :set_file | :unset | :upgraded,
            optional(:status) => nil | non_neg_integer(),
            optional(:transport_pid) => nil | pid(),
            optional(:view) => atom()
          },
          any()
        ) :: Plug.Conn.t()
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

  def wip(conn, _params) do
    conn
    |> put_open_graph_metadata(%{
      title: "Work in progress",
      description: "We are finishing up the first version of our website. Please come back later."
    })
    |> render(:wip)
  end

  def blog_post(%{request_path: slug} = conn, _params) do
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
