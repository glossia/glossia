defmodule GlossiaWeb.LegalControllerTest do
  use GlossiaWeb.ConnCase, async: true

  test "current legal pages reference O'Saasy", %{conn: conn} do
    for path <- [~p"/terms", ~p"/privacy", ~p"/cookies"] do
      response = conn |> get(path) |> html_response(200)

      assert response =~ "O'Saasy License"
      refute response =~ "MPL-2.0"
    end
  end

  test "current terms distinguish commercial use from competing hosting", %{conn: conn} do
    response = conn |> get(~p"/terms") |> html_response(200)

    assert response =~ "sell copies of"
    assert response =~ "You may not use the software"
    assert response =~ "directly compete with the original licensor"
    assert response =~ "source-available rather than open source"
    refute response =~ "commercial or competing hosted services"
  end

  test "localized terms fall back to the current O'Saasy policy", %{conn: conn} do
    response = conn |> get(~p"/es/terms") |> html_response(200)

    assert response =~ "directly compete with the original licensor"
    assert response |> LazyHTML.from_document() |> LazyHTML.text() =~ "Licencia O'Saasy"
    refute response =~ "MPL-2.0"
  end

  test "historical terms remain available", %{conn: conn} do
    response = conn |> get(~p"/terms/2026-02-12") |> html_response(200)

    assert response =~ "O'Saasy License"
    assert response =~ "may not use it to offer"
  end
end
