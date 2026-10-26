defmodule GlossiaWeb.LegalControllerTest do
  use GlossiaWeb.ConnCase, async: true

  test "current legal pages reference Apache core and enterprise licensing", %{conn: conn} do
    for path <- [~p"/terms", ~p"/privacy", ~p"/cookies"] do
      response = conn |> get(path) |> html_response(200)

      assert response =~ "Apache-2.0"
      assert response =~ "Glossia Enterprise License"
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
  end
end
