defmodule Glossia.Foundation.Builds.Web.Controllers.APIControllerTest do
  use Glossia.Web.ConnCase

  test "not_found", %{conn: conn} do
    # Given/When
    conn = get(conn, ~p"/builder-api/invalid")

    # Then
    assert %{"errors" => [%{"detail" => "GET /builder-api/invalid is an invalid resource"}]} =
             json_response(conn, 404)
  end
end