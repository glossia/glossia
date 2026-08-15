defmodule Glossia.Legal do
  alias Glossia.Legal.Version

  use Glossia.ContentPublisher,
    build: Version,
    from: Application.app_dir(:glossia, "priv/legal/**/*.md"),
    i18n: "legal",
    as: :versions,
    html_converter: Glossia.Markdown.Publisher,
    markdown_options: [breaks: true]

  @versions Enum.sort_by(@versions, & &1.date, {:desc, Date})

  @versions_by_locale Map.new(@versions_by_locale, fn {locale, versions} ->
                        {locale, Enum.sort_by(versions, & &1.date, {:desc, Date})}
                      end)

  def all_versions(locale \\ Glossia.I18n.default_locale()) do
    Map.get(@versions_by_locale, locale, @versions)
  end

  def versions_for(document, locale \\ Glossia.I18n.default_locale()) do
    locale |> all_versions() |> Enum.filter(&(&1.document == document))
  end

  def latest_version!(document, locale \\ Glossia.I18n.default_locale()) do
    case versions_for(document, locale) do
      [latest | _] -> latest
      [] -> raise Glossia.Legal.NotFoundError, "no versions found for document=#{document}"
    end
  end

  def get_version!(document, date_string, locale \\ Glossia.I18n.default_locale()) do
    date = Date.from_iso8601!(date_string)

    Enum.find(all_versions(locale), fn v -> v.document == document and v.date == date end) ||
      raise Glossia.Legal.NotFoundError,
            "version not found for document=#{document}, date=#{date_string}"
  end
end

defmodule Glossia.Legal.NotFoundError do
  defexception [:message, plug_status: 404]
end
