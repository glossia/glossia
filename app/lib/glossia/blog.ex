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

  use Glossia.ContentPublisher,
    build: Post,
    from: Application.app_dir(:glossia, "priv/blog/**/*.md"),
    i18n: "blog",
    as: :posts,
    html_converter: Glossia.Markdown.Publisher

  @posts Enum.sort_by(@posts, & &1.date, {:desc, Date})

  @posts_by_locale Map.new(@posts_by_locale, fn {locale, posts} ->
                     {locale, Enum.sort_by(posts, & &1.date, {:desc, Date})}
                   end)

  def all_posts(locale \\ Glossia.I18n.default_locale()) do
    Map.get(@posts_by_locale, locale, @posts)
  end

  def recent_posts(limit \\ 3, locale \\ Glossia.I18n.default_locale()) do
    locale |> all_posts() |> Enum.take(limit)
  end

  def get_post!(slug, locale \\ Glossia.I18n.default_locale()) do
    Enum.find(all_posts(locale), &(&1.slug == slug)) ||
      raise Glossia.Blog.NotFoundError, "blog post not found: #{slug}"
  end
end

defmodule Glossia.Blog.NotFoundError do
  defexception [:message, plug_status: 404]
end
