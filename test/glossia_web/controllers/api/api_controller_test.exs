defmodule GlossiaWeb.API.APIControllerTest do
  use GlossiaWeb.ConnCase

  test "not_found", %{conn: conn} do
    # Given/When
    conn = get(conn, ~p"/api/invalid")

    # Then
    assert %{"errors" => [%{"detail" => "GET /api/invalid is an invalid resource"}]} =
             json_response(conn, 404)
  end
end
