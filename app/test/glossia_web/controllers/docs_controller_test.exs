defmodule GlossiaWeb.DocsControllerTest do
  use GlossiaWeb.ConnCase, async: true

  # Crawlers reach for paths like `/docs/index.html`. An unknown category is a missing page,
  # not a server fault, so it has to come back as a 404 rather than blowing up in the view.
  test "answers an unknown docs category with a 404", %{conn: conn} do
    assert_error_sent 404, fn -> get(conn, ~p"/docs/index.html") end
  end

  test "renders the Gettext ecosystem guide and its sidebar section", %{conn: conn} do
    html =
      conn
      |> get(~p"/docs/how-to/elixir-phoenix-gettext")
      |> html_response(200)

    assert html =~ ~s(data-section="ecosystems")
    assert html =~ "Ecosystems"
    assert html =~ "Elixir and Phoenix (Gettext)"
    assert html =~ "sort_by_msgid"
  end

  test "serves the ecosystem guide through localized English fallback", %{conn: conn} do
    html =
      conn
      |> get(~p"/es/docs/how-to/elixir-phoenix-gettext")
      |> html_response(200)

    assert html =~ ~s(data-section="ecosystems")
    assert html =~ "sort_by_msgid"
  end

  test "labels enterprise documentation in every locale and Markdown representation", %{
    conn: conn
  } do
    for locale <- Glossia.I18n.locales(),
        {category, slug} <- [
          {"reference", "isolated-translation-runners"},
          {"reference", "audit-logs"},
          {"how-to", "organization-sign-in"}
        ] do
      path = Glossia.I18n.localize_path(locale, ~p"/docs/#{category}/#{slug}")
      html = conn |> get(path) |> html_response(200) |> LazyHTML.from_document()

      assert html
             |> LazyHTML.query("[data-part=availability] .noora-badge")
             |> LazyHTML.text()
             |> String.trim() ==
               "Enterprise"

      assert html |> LazyHTML.query("[data-part=availability] a") |> LazyHTML.attribute("href") ==
               [Glossia.I18n.localize_path(locale, ~p"/docs/explanation/editions")]

      assert html |> LazyHTML.query("#docs-page-markdown") |> LazyHTML.text() =~
               "**Edition: Enterprise.**"

      markdown_slug = "#{slug}.md"

      markdown_path =
        Glossia.I18n.localize_path(locale, ~p"/docs/#{category}/#{markdown_slug}")

      assert conn |> get(markdown_path) |> response(200) =~ "**Edition: Enterprise.**"
    end

    assert conn |> get(~p"/llms-full.txt") |> response(200) =~ "**Edition: Enterprise.**"

    html =
      conn
      |> get(~p"/docs/reference/l10n-md")
      |> html_response(200)
      |> LazyHTML.from_document()

    assert html
           |> LazyHTML.query("[data-part=availability] .noora-badge")
           |> LazyHTML.text()
           |> String.trim() ==
             "Community and Enterprise"
  end

  test "the edition comparison omits its own comparison link in every locale", %{conn: conn} do
    for locale <- Glossia.I18n.locales() do
      path = Glossia.I18n.localize_path(locale, ~p"/docs/explanation/editions")
      html = conn |> get(path) |> html_response(200) |> LazyHTML.from_document()

      assert html
             |> LazyHTML.query("[data-part=availability] .noora-badge")
             |> LazyHTML.text()
             |> String.trim() == "Community and Enterprise"

      assert html |> LazyHTML.query("[data-part=availability] a") |> Enum.empty?()
    end
  end

  test "every recovery translation identifies engine release recovery as Enterprise", %{
    conn: conn
  } do
    for locale <- Glossia.I18n.locales() do
      path = Glossia.I18n.localize_path(locale, ~p"/docs/explanation/translation-recovery.md")
      markdown = conn |> get(path) |> response(200)

      runner_path =
        Glossia.I18n.localize_path(locale, ~p"/docs/reference/isolated-translation-runners")

      assert markdown =~ runner_path
      assert markdown =~ ~r/\*\*[^\n*]*Enterprise[^\n*]*\*\*/
    end
  end

  test "returns documentation results for a search query", %{conn: conn} do
    response =
      conn
      |> get(~p"/docs/search.json?#{[locale: "en", q: "getting started"]}")
      |> json_response(200)

    assert [%{"title" => "Getting started", "url" => "/docs/tutorials/getting-started"} | _] =
             response["results"]
  end
end
