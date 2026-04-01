defmodule GlossiaWeb.WaitlistControllerTest do
  use GlossiaWeb.ConnCase, async: true

  alias Glossia.Waitlist
  alias Glossia.TestHelpers

  describe "GET /interest" do
    test "redirects users with access to dashboard", %{conn: conn} do
      user = TestHelpers.create_user("has-access@test.com", "hasaccess", has_access: true)

      conn =
        conn
        |> init_test_session(%{user_id: user.id})
        |> get("/interest")

      assert redirected_to(conn) == "/dashboard"
    end

    test "renders waitlist form for users without access", %{conn: conn} do
      user = TestHelpers.create_user("no-access@test.com", "noaccess", has_access: false)

      conn =
        conn
        |> init_test_session(%{user_id: user.id})
        |> get("/interest")

      assert html_response(conn, 200) =~ "Tell us about your project"
    end
  end

  describe "POST /interest" do
    test "redirects users with access to dashboard and does not create submission", %{conn: conn} do
      user =
        TestHelpers.create_user("has-access-post@test.com", "hasaccesspost", has_access: true)

      conn =
        conn
        |> init_test_session(%{user_id: user.id})
        |> post("/interest", %{
          "submission" => %{
            "company" => "Acme",
            "url" => "https://example.com",
            "description" => "Acme product",
            "motivation" => "We need localization",
            "target_languages" => "Spanish"
          }
        })

      assert redirected_to(conn) == "/dashboard"
      assert Waitlist.get_submission_by_user(user.id) == nil
    end
  end
end
