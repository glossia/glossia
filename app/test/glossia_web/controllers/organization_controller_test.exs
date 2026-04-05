defmodule GlossiaWeb.OrganizationControllerTest do
  use GlossiaWeb.ConnCase, async: true

  alias Glossia.Accounts
  alias Glossia.Repo
  alias Glossia.TestHelpers

  describe "GET /organizations/new" do
    test "renders the form for an authenticated user", %{conn: conn} do
      user = TestHelpers.create_user("org-new@test.com", "org-new")

      conn =
        conn
        |> init_test_session(%{user_id: user.id})
        |> get("/organizations/new")

      assert html_response(conn, 200) =~ "New organization"
    end
  end

  describe "POST /organizations" do
    test "creates an organization and redirects", %{conn: conn} do
      user = TestHelpers.create_user("org-create@test.com", "org-create")

      conn =
        TestHelpers.expect_event(
          "organization.created",
          fn ->
            conn
            |> init_test_session(%{user_id: user.id})
            |> post("/organizations", %{
              "account" => %{
                "handle" => "created-org-#{System.unique_integer([:positive])}",
                "name" => "Created Org"
              }
            })
          end,
          %{
            :account_id => fn id -> is_binary(id) end,
            :user_id => user.id,
            {:opt, :resource_type} => "organization"
          }
        )

      assert redirected_to(conn) =~ "/created-org-"
    end

    test "renders errors for invalid params", %{conn: conn} do
      user = TestHelpers.create_user("org-invalid@test.com", "org-invalid")

      conn =
        conn
        |> init_test_session(%{user_id: user.id})
        |> post("/organizations", %{"account" => %{"handle" => "A", "name" => "Bad"}})

      assert html_response(conn, 200) =~ "must start with a letter"
    end

    test "redirects when the user is not allowed to create organizations", %{conn: conn} do
      user = TestHelpers.create_user("org-no-access@test.com", "org-no-access", has_access: false)

      conn =
        conn
        |> init_test_session(%{user_id: user.id})
        |> post("/organizations", %{
          "account" => %{"handle" => "blocked-org", "name" => "Blocked Org"}
        })

      assert redirected_to(conn) == "/interest"
      refute Repo.get_by(Accounts.Account, handle: "blocked-org")
    end
  end
end
