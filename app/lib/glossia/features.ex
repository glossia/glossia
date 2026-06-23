defmodule Glossia.Features.Page do
  @moduledoc false

  @enforce_keys [
    :id,
    :slug,
    :title,
    :summary,
    :order,
    :icon,
    :hero_cta_text,
    :hero_cta_url,
    :highlights,
    :body
  ]
  defstruct [
    :id,
    :slug,
    :title,
    :summary,
    :order,
    :icon,
    :hero_cta_text,
    :hero_cta_url,
    :highlights,
    :body
  ]

  def build(filename, attrs, body) do
    slug =
      filename
      |> Path.rootname()
      |> Path.basename()

    {body, _toc} = Glossia.MarketingMarkdown.process(body)

    attrs
    |> Map.put_new(:slug, slug)
    |> Map.merge(%{id: slug, body: body})
    |> then(&struct!(__MODULE__, &1))
  end
end

defmodule Glossia.Features do
  @moduledoc false

  alias Glossia.Features.Page

  use Glossia.ContentPublisher,
    build: Page,
    from: Application.app_dir(:glossia, "priv/features/**/*.md"),
    as: :pages,
    html_converter: Glossia.Markdown.Publisher

  @pages Enum.sort_by(@pages, & &1.order)

  def all_pages, do: @pages

  def get_page!(slug) do
    Enum.find(@pages, &(&1.slug == slug)) ||
      raise Glossia.Features.NotFoundError, "feature page not found: #{slug}"
  end
end

defmodule Glossia.Features.NotFoundError do
  defexception [:message, plug_status: 404]
end
