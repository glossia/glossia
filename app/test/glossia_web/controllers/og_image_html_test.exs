defmodule GlossiaWeb.OgImageHTMLTest do
  use ExUnit.Case, async: true

  alias GlossiaWeb.OgImageHTML

  test "the editorial preview keeps the project logo, section badge, and footer branding" do
    logo = "data:image/png;base64,cHJvamVjdA=="

    html =
      OgImageHTML.document(
        %{title: "Tuist", description: "dev/tuist · Translations", category: "Translations"},
        logo
      )

    document = LazyHTML.from_document(html)

    assert document
           |> LazyHTML.query("main [data-part=project-logo]")
           |> LazyHTML.attribute("src") == [logo]

    assert document |> LazyHTML.query("main .noora-badge") |> LazyHTML.text() |> String.trim() ==
             "Translations"

    assert document |> LazyHTML.query("main h1") |> LazyHTML.text() == "Tuist"
    assert document |> LazyHTML.query("footer [data-part=brand]") |> LazyHTML.text() =~ "Glossia"
    assert html =~ "font-family: \"Source Serif 4\""
    assert html =~ "data:font/woff2;base64,"
    assert document |> LazyHTML.query("link[href], script") |> Enum.empty?()
  end

  test "a project without a logo uses the brand and page content stays escaped" do
    html = OgImageHTML.document(%{title: "<script>bad</script>", category: "Overview"}, nil)
    document = LazyHTML.from_document(html)

    assert document
           |> LazyHTML.query("main [data-part=project-logo]")
           |> LazyHTML.attribute("src") ==
             document |> LazyHTML.query("footer img") |> LazyHTML.attribute("src")

    assert document |> LazyHTML.query("h1") |> LazyHTML.text() == "<script>bad</script>"
    assert document |> LazyHTML.query("script, main p") |> Enum.empty?()
  end
end
