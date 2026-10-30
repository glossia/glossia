defmodule GlossiaWeb.MarkdownPaths do
  @moduledoc false

  use GlossiaWeb, :verified_routes

  alias Glossia.I18n

  def for_path(path) do
    {locale, path} = I18n.split_path(path)
    segments = path |> URI.parse() |> Map.fetch!(:path) |> Path.split() |> Enum.drop(1)

    markdown =
      case segments do
        [] ->
          path(%URI{}, ~p"/index.md")

        ["docs"] ->
          path(%URI{}, ~p"/docs.md")

        ["blog"] ->
          path(%URI{}, ~p"/blog.md")

        ["features"] ->
          path(%URI{}, ~p"/features.md")

        ["changelog"] ->
          path(%URI{}, ~p"/changelog.md")

        ["terms"] ->
          path(%URI{}, ~p"/terms.md")

        ["privacy"] ->
          path(%URI{}, ~p"/privacy.md")

        ["cookies"] ->
          path(%URI{}, ~p"/cookies.md")

        ["acceptable-use"] ->
          path(%URI{}, ~p"/acceptable-use.md")

        ["imprint"] ->
          path(%URI{}, ~p"/imprint.md")

        ["blog", slug] ->
          path(%URI{}, ~p"/blog/#{slug <> ".md"}")

        ["features", slug] ->
          path(%URI{}, ~p"/features/#{slug <> ".md"}")

        ["docs", category] ->
          path(%URI{}, ~p"/docs/#{category <> ".md"}")

        ["docs", category, section] ->
          path(%URI{}, ~p"/docs/#{category}/#{section <> ".md"}")

        ["docs", category, subcategory, slug] ->
          path(%URI{}, ~p"/docs/#{category}/#{subcategory}/#{slug <> ".md"}")

        ["terms", date] ->
          path(%URI{}, ~p"/terms/#{date <> ".md"}")

        ["privacy", date] ->
          path(%URI{}, ~p"/privacy/#{date <> ".md"}")

        ["cookies", date] ->
          path(%URI{}, ~p"/cookies/#{date <> ".md"}")

        ["acceptable-use", date] ->
          path(%URI{}, ~p"/acceptable-use/#{date <> ".md"}")

        ["imprint", date] ->
          path(%URI{}, ~p"/imprint/#{date <> ".md"}")
      end

    I18n.localize_path(locale, markdown)
  end
end
