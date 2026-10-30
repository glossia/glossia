defmodule GlossiaWeb.LegalControllerTest do
  use GlossiaWeb.ConnCase, async: true

  test "current legal pages reference Apache core and enterprise licensing", %{conn: conn} do
    for path <- [~p"/terms", ~p"/privacy", ~p"/cookies", ~p"/acceptable-use", ~p"/imprint"] do
      response = conn |> get(path) |> html_response(200)

      assert response =~ "Apache-2.0"
      assert response =~ "Glossia Enterprise License"
      assert response =~ "Pedro Piñera Buendía"
      refute Glossia.Legal.latest_version!(Path.basename(path)).body =~ "O'Saasy"
    end
  end

  test "current terms permit core hosting and require enterprise production permission", %{
    conn: conn
  } do
    response = conn |> get(~p"/terms") |> html_response(200)

    assert response =~ "competing hosted services"
    assert response =~ "source-available, not open source"
    assert response =~ "requires a separate written commercial agreement"
    assert response =~ ~s(href="https://github.com/glossia/glossia/blob/main/ee/LICENSE.md")
    refute response =~ "You may not use the software"
  end

  test "localized terms fall back to the current open-core policy", %{conn: conn} do
    response = conn |> get(~p"/es/terms") |> html_response(200)
    version = Glossia.Legal.latest_version!("terms", "es")

    assert version.date == Glossia.Legal.latest_version!("terms").date
    assert response =~ version.body
    assert response =~ ~s(href="https://github.com/glossia/glossia/blob/main/LICENSE.md")
    assert response |> LazyHTML.from_document() |> LazyHTML.text() =~ "Apache-2.0"
    refute response =~ "MPL-2.0"
  end

  test "historical terms remain available", %{conn: conn} do
    response = conn |> get(~p"/terms/2026-02-12") |> html_response(200)

    assert response =~ "O'Saasy License"
    assert response =~ "may not use it to offer"
    assert response =~ "You are viewing a previous version."
    assert response =~ ~s(href="/terms")
  end

  test "new legal documents are discoverable, localized and versioned", %{conn: conn} do
    sitemap = conn |> get(~p"/sitemap.xml") |> response(200)
    homepage = conn |> get(~p"/es") |> html_response(200)

    for path <- [~p"/acceptable-use", ~p"/imprint"] do
      localized_path = Glossia.I18n.localize_path("es", path)
      html = conn |> get(localized_path) |> html_response(200)
      assert html =~ "Pedro Piñera Buendía"
      assert html =~ ~s(href="#{localized_path}")
      assert homepage =~ ~s(href="#{localized_path}")
      assert sitemap =~ "#{localized_path}</loc>"

      for version_path <- [localized_path, Path.join(localized_path, "2026-10-30")] do
        markdown = conn |> get(Glossia.PublicContent.markdown_path(version_path)) |> response(200)
        assert markdown =~ "Pedro Piñera Buendía"
        refute markdown =~ "<!DOCTYPE"
      end
    end

    dated = conn |> get(~p"/terms/2026-10-30") |> html_response(200)
    refute dated =~ "You are viewing a previous version."
  end

  test "privacy and cookie notices disclose implemented processing", %{conn: conn} do
    privacy = conn |> get(~p"/privacy") |> html_response(200)
    cookies = conn |> get(~p"/cookies") |> html_response(200)

    assert privacy =~ "analytics.glossia.ai"
    assert privacy =~ "Google Fonts"
    assert privacy =~ "model providers"
    assert cookies =~ "_glossia_key"
    assert cookies =~ "glossia_locale"
    assert cookies =~ "365 days"
    assert cookies =~ "sessionStorage"
    refute privacy =~ "No Analytics or Tracking"
    refute cookies =~ "No external services are loaded"
  end
end
