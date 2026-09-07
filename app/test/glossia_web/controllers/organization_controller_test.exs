defmodule GlossiaWeb.OrganizationControllerTest do
  use GlossiaWeb.ConnCase, async: true

  alias Glossia.Organizations
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
  end

  describe "POST /:handle/-/claim" do
    test "claims an available organization for the signed-in user", %{conn: conn} do
      claimant = TestHelpers.create_user("claim-route@test.com", "claim-route")
      handle = "claim-route-#{System.unique_integer([:positive])}"

      {:ok, %{organization: organization}} =
        Organizations.create_claimable_organization(%{
          handle: handle,
          name: "Claim route organization"
        })

      conn =
        conn
        |> init_test_session(%{user_id: claimant.id})
        |> post("/#{handle}/-/claim")

      assert redirected_to(conn) == "/#{handle}"

      organization = Organizations.get_organization(organization.id)
      refute organization.claimable
      assert %{role: "admin"} = Organizations.get_membership(organization, claimant)
    end
  end
end
