defmodule BabelWeb.OAuth.AuthorizeControllerTest do
  use BabelWeb.ConnCase, async: true

  test "rejects request URI authorization parameters", %{conn: conn} do
    conn = get(conn, ~p"/oauth/authorize?#{%{request_uri: "https://example.com/request"}}")

    assert json_response(conn, :bad_request) == %{"error" => "invalid_request"}
  end
end
