defmodule GlossiaWeb.Auth.PoliciesTest do
  # https://thoughtbot.com/blog/testing-elixir-plugs
  use GlossiaWeb.ConnCase
  alias GlossiaWeb.Auth.Policies

  test "returns unauthorized if the project is missing", %{conn: conn} do
    # Given
    opts = Policies.init(:current_project)

    # When
    conn = conn |> Policies.call(opts)

    # Then
    assert %{"errors" => [%{"detail" => "You need to be authenticated to access this resource"}]} =
             json_response(conn, 401)
  end
end
