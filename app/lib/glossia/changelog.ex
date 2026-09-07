defmodule Glossia.Changelog.Entry do
  @moduledoc false

  @enforce_keys [:id, :slug, :title, :summary, :date, :body]
  defstruct [:id, :slug, :title, :summary, :date, :body]

  def build(filename, attrs, body) do
    id =
      filename
      |> Path.rootname()
      |> Path.basename()

    parts = String.split(id, "-")

    fallback_date =
      parts
      |> Enum.take(3)
      |> Enum.join("-")
      |> Date.from_iso8601!()

    fallback_slug =
      parts
      |> Enum.drop(3)
      |> Enum.join("-")

    {body, _toc} = Glossia.MarketingMarkdown.process(body)

    attrs
    |> Map.put_new(:date, fallback_date)
    |> Map.put_new(:slug, fallback_slug)
    |> Map.merge(%{id: id, body: body})
    |> then(&struct!(__MODULE__, &1))
  end
end

defmodule Glossia.Changelog do
  @moduledoc false

  alias Glossia.Changelog.Entry

  use Glossia.ContentPublisher,
    build: Entry,
    from: Application.app_dir(:glossia, "priv/changelog/**/*.md"),
    i18n: "changelog",
    as: :entries,
    html_converter: Glossia.Markdown.Publisher

  @entries Enum.sort_by(@entries, & &1.date, {:desc, Date})

  @entries_by_locale Map.new(@entries_by_locale, fn {locale, entries} ->
                       {locale, Enum.sort_by(entries, & &1.date, {:desc, Date})}
                     end)

  def all_entries(locale \\ Glossia.I18n.default_locale()) do
    Map.get(@entries_by_locale, locale, @entries)
  end

  def recent_entries(limit \\ 20, locale \\ Glossia.I18n.default_locale()) do
    locale |> all_entries() |> Enum.take(limit)
  end
end
