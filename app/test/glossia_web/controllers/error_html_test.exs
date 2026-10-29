defmodule GlossiaWeb.ErrorHTMLTest do
  use GlossiaWeb.ConnCase, async: true

  import Phoenix.Template, only: [render_to_string: 4]

  test "renders a standalone 404 with a way back home" do
    html = render_to_string(GlossiaWeb.ErrorHTML, "404", "html", [])
    document = LazyHTML.from_document(html)

    assert LazyHTML.text(LazyHTML.query(document, "h1")) == "This page got lost in translation"
    assert LazyHTML.attribute(LazyHTML.query(document, "main a"), "href") == ["/", "/"]

    assert LazyHTML.attribute(LazyHTML.query(document, "link[rel=stylesheet]"), "href") ==
             ["/assets/styles.css", "/assets/noora.css"]

    assert html =~ "<!DOCTYPE html>"

    assert LazyHTML.attribute(LazyHTML.query(document, "script"), "src") == [
             "/assets/js/error.js"
           ]
  end

  test "renders server errors without exposing the exception" do
    html =
      render_to_string(GlossiaWeb.ErrorHTML, "500", "html",
        reason: RuntimeError.exception("private database credentials")
      )

    assert html =~ "Something went wrong on our side"
    refute html =~ "private database credentials"
  end

  test "preserves the retry delay on rate-limit pages" do
    html = render_to_string(GlossiaWeb.ErrorHTML, "429", "html", retry_after: 17)

    assert html =~ "Slow down for a moment"
    assert html =~ "Try again in 17 seconds."
  end

  test "other HTTP errors use the same page" do
    html = render_to_string(GlossiaWeb.ErrorHTML, "403", "html", [])

    assert html =~ "Forbidden"
    assert html =~ ~s(id="error-page")
  end

  test "home links and document language follow the current locale" do
    Gettext.with_locale(GlossiaWeb.Gettext, "es", fn ->
      document =
        GlossiaWeb.ErrorHTML
        |> render_to_string("404", "html", [])
        |> LazyHTML.from_document()

      assert LazyHTML.attribute(LazyHTML.query(document, "html"), "lang") == ["es"]
      assert LazyHTML.attribute(LazyHTML.query(document, "main a"), "href") == ["/es", "/es"]
    end)
  end

  test "controller-rendered errors do not nest inside the application layout", %{conn: conn} do
    html = conn |> get(~p"/-/locale/unknown") |> html_response(404)

    assert html =~ ~s(id="error-page")
    assert length(Regex.scan(~r/<!DOCTYPE html>/i, html)) == 1
    refute html =~ ~s(class="site-header")
  end
end
