defmodule GlossiaWeb.GithubInstallCallbackControllerTest do
  use GlossiaWeb.ConnCase, async: true

  alias Glossia.TestHelpers

  test "GET /callbacks/github/install handles invalid installation IDs without crashing", %{
    conn: conn
  } do
    %{account: account} =
      user =
      TestHelpers.create_user("install-callback@test.com", "install-callback")

    conn =
      conn
      |> init_test_session(%{})
      |> put_session(:user_id, user.id)
      |> get("/callbacks/github/install", %{"installation_id" => "invalid"})

    assert redirected_to(conn) == "/#{account.handle}/-/settings/github"
  end
end
