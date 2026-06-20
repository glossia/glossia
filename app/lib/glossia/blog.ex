defmodule Glossia.Blog.Post do
  @moduledoc false

  @enforce_keys [:id, :slug, :title, :summary, :date, :author, :body]
  defstruct [
    :id,
    :slug,
    :title,
    :summary,
    :date,
    :author,
    :body,
    :cta_title,
    :cta_description,
    :cta_text,
    :cta_url
  ]

  @authors %{
    "pedro" => %{
      id: "pedro",
      name: "Pedro Pinera Buendia",
      avatar: "https://unavatar.io/x/pepicrft",
      linkedin: "https://linkedin.com/in/pepicrft",
      mastodon: "https://mastodon.social/@pepicrft",
      x: "https://x.com/pepicrft",
      github: "https://github.com/pepicrft"
    }
  }

  def build(filename, attrs, body) do
    id =
      filename
      |> Path.rootname()
      |> Path.basename()

    fallback_date =
      id
      |> String.split("-")
      |> Enum.take(3)
      |> Enum.join("-")
      |> Date.from_iso8601!()

    {body, _toc} = Glossia.MarketingMarkdown.process(body)

    attrs
    |> Map.put_new(:slug, id)
    |> Map.put_new(:date, fallback_date)
    |> Map.put_new(:cta_title, nil)
    |> Map.put_new(:cta_description, nil)
    |> Map.put_new(:cta_text, nil)
    |> Map.put_new(:cta_url, nil)
    |> Map.merge(%{
      id: id,
      author: author!(attrs[:author]),
      body: body
    })
    |> then(&struct!(__MODULE__, &1))
  end

  defp author!(author_id), do: Map.fetch!(@authors, author_id)
end

defmodule Glossia.Blog do
  @moduledoc false

  alias Glossia.Blog.Post

  use NimblePublisher,
    build: Post,
    from: Application.app_dir(:glossia, "priv/blog/**/*.md"),
    as: :posts,
    earmark_options: %Earmark.Options{code_class_prefix: "language-"}

  @posts Enum.sort_by(@posts, & &1.date, {:desc, Date})

  def all_posts, do: @posts
  def recent_posts(limit \\ 3), do: Enum.take(@posts, limit)

  def get_post!(slug) do
    Enum.find(@posts, &(&1.slug == slug)) ||
      raise Glossia.Blog.NotFoundError, "blog post not found: #{slug}"
  end
end

defmodule Glossia.Blog.NotFoundError do
  defexception [:message, plug_status: 404]
end
