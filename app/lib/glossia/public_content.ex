defmodule Glossia.PublicContent.Builder do
  @moduledoc false

  use GlossiaWeb, :verified_routes

  alias Glossia.{Docs, I18n}
  alias GlossiaWeb.MarkdownPaths

  def build(locale, home, doc_pages, feature_pages, blog_posts, legal_versions, changelog_entries) do
    docs =
      Enum.map(doc_pages, fn page ->
        body =
          page.raw_markdown ||
            "See the [OpenAPI specification](#{path(%URI{}, ~p"/api/openapi.json")}) for endpoint schemas."

        {Docs.path_for(page), render(page.title, page.summary, availability(page) <> body)}
      end)

    markdown_only =
      Enum.map(Docs.markdown_only_pages(locale), fn page ->
        {Docs.path_for(page), render(page.title, page.summary, page.raw_markdown)}
      end)

    features =
      Enum.map(feature_pages, fn page ->
        {path(%URI{}, ~p"/features/#{page.slug}"),
         render(page.title, page.summary, availability(page) <> page.raw_markdown)}
      end)

    blog =
      Enum.map(blog_posts, fn post ->
        {path(%URI{}, ~p"/blog/#{post.slug}"),
         render(post.title, post.summary, post.raw_markdown)}
      end)

    legal =
      Enum.flat_map(Glossia.Legal.documents(), fn document ->
        path =
          case document do
            "terms" -> path(%URI{}, ~p"/terms")
            "privacy" -> path(%URI{}, ~p"/privacy")
            "cookies" -> path(%URI{}, ~p"/cookies")
            "acceptable-use" -> path(%URI{}, ~p"/acceptable-use")
            "imprint" -> path(%URI{}, ~p"/imprint")
          end

        versions =
          Enum.map(Enum.filter(legal_versions, &(&1.document == document)), fn version ->
            version_path =
              case document do
                "terms" ->
                  path(%URI{}, ~p"/terms/#{Date.to_iso8601(version.date)}")

                "privacy" ->
                  path(%URI{}, ~p"/privacy/#{Date.to_iso8601(version.date)}")

                "cookies" ->
                  path(%URI{}, ~p"/cookies/#{Date.to_iso8601(version.date)}")

                "acceptable-use" ->
                  path(%URI{}, ~p"/acceptable-use/#{Date.to_iso8601(version.date)}")

                "imprint" ->
                  path(%URI{}, ~p"/imprint/#{Date.to_iso8601(version.date)}")
              end

            {version_path,
             render(version.title, "Effective #{version.date}.", version.raw_markdown)}
          end)

        [{path, versions |> hd() |> elem(1)} | versions]
      end)

    categories =
      Enum.map(~w(tutorials how-to reference explanation), fn category ->
        category_pages = Enum.filter(doc_pages, &(&1.category == category))
        paths = MapSet.new(category_pages, &Docs.path_for/1)

        {path(%URI{}, ~p"/docs/#{category}"),
         index(category, Enum.filter(docs, &(elem(&1, 0) in paths)), locale)}
      end)

    subcategories =
      Enum.map(~w(cli apis mcp), fn subcategory ->
        paths =
          doc_pages
          |> Enum.filter(&(&1.category == "reference" and &1.subcategory == subcategory))
          |> MapSet.new(&Docs.path_for/1)

        {path(%URI{}, ~p"/docs/reference/#{subcategory}"),
         index(subcategory, Enum.filter(docs, &(elem(&1, 0) in paths)), locale)}
      end)

    changelog =
      Enum.map_join(changelog_entries, "\n\n", fn entry ->
        "## #{entry.title}\n\n#{entry.date}\n\n#{entry.raw_markdown}"
      end)

    Map.new(
      docs ++
        markdown_only ++
        features ++
        blog ++
        legal ++
        categories ++
        subcategories ++
        [
          {path(%URI{}, ~p"/"), home},
          {path(%URI{}, ~p"/docs"), index("Documentation", docs, locale)},
          {path(%URI{}, ~p"/features"), index("Features", features, locale)},
          {path(%URI{}, ~p"/blog"), index("Blog", blog, locale)},
          {path(%URI{}, ~p"/changelog"), "# Changelog\n\n#{changelog}\n"}
        ]
    )
  end

  defp render(title, summary, body), do: "# #{title}\n\n#{summary}\n\n#{body}\n"

  def availability(%{edition: "enterprise"}), do: "**Edition: Enterprise.**\n\n"
  def availability(_page), do: "**Editions: Community and Enterprise.**\n\n"

  defp index(title, pages, locale) do
    links =
      Enum.map_join(pages, "\n", fn {path, markdown} ->
        heading = markdown |> String.split("\n", parts: 2) |> hd() |> String.trim_leading("# ")
        markdown_path = locale |> I18n.localize_path(path) |> MarkdownPaths.for_path()
        "- [#{heading}](#{markdown_path})"
      end)

    "# #{title}\n\n#{links}\n"
  end
end

defmodule Glossia.PublicContent do
  @moduledoc """
  Published Markdown representations, built from the same sources as the website.

  The inventory is finite and compiled into the release. Serving it needs no
  database, translation gateway, HTML conversion, or user-controlled cache keys.
  """

  alias Glossia.{Blog, Changelog, Docs, Features, I18n, Legal, PublicContent.Builder}

  @home_source Application.app_dir(:glossia, "priv/marketing/home.md")
  @external_resource @home_source
  @home File.read!(@home_source)
  @home_paths Map.new(I18n.locales(), fn locale ->
                {locale, Application.app_dir(:glossia, "priv/i18n/#{locale}/marketing/home.md")}
              end)

  # Track even unpublished locale sources, so adding a translation rebuilds the
  # inventory instead of continuing to serve the compiled English fallback.
  for {_locale, source} <- @home_paths do
    @external_resource source
  end

  @homes Map.new(@home_paths, fn {locale, source} ->
           {locale, if(File.exists?(source), do: File.read!(source), else: @home)}
         end)

  # Invoke every publisher here so Mix tracks explicit compile dependencies.
  # Otherwise newly added content could update HTML without rebuilding Markdown.
  @documents Map.new(I18n.locales(), fn locale ->
               {locale,
                Builder.build(
                  locale,
                  Map.fetch!(@homes, locale),
                  Docs.all_pages(locale),
                  Features.all_pages(locale),
                  Blog.all_posts(locale),
                  Legal.all_versions(locale),
                  Changelog.all_entries(locale)
                )}
             end)

  @markdown_only_paths MapSet.new(Docs.markdown_only_pages(), &Docs.path_for/1)

  def documents(locale \\ I18n.default_locale()), do: Map.fetch!(@documents, locale)

  def markdown_only?(path) do
    {_locale, path} = I18n.split_path(path)
    MapSet.member?(@markdown_only_paths, path)
  end

  def get(path) do
    {locale, path} = I18n.split_path(path)
    Map.get(documents(locale), path)
  end

  def markdown_path(path), do: GlossiaWeb.MarkdownPaths.for_path(path)
end
