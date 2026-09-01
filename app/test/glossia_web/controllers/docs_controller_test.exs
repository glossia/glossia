defmodule GlossiaWeb.DocsControllerTest do
  use GlossiaWeb.ConnCase, async: true

  # Crawlers reach for paths like `/docs/index.html`. An unknown category is a missing page,
  # not a server fault, so it has to come back as a 404 rather than blowing up in the view.
  test "answers an unknown docs category with a 404", %{conn: conn} do
    assert_error_sent 404, fn -> get(conn, ~p"/docs/index.html") end
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
