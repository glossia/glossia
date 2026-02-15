defmodule GlossiaWeb.Api.AccountApiControllerTest do
  use GlossiaWeb.ConnCase, async: true

  alias Glossia.Organizations
  alias GlossiaWeb.ApiTestHelpers

  @scopes ~w(account:read)

  setup do
    user = ApiTestHelpers.create_user("account-api@test.com", "account-api")
    %{user: user}
  end

  describe "GET /api/accounts" do
    test "lists accounts for the authenticated user", %{conn: conn, user: user} do
      {:ok, %{account: org_account}} =
        Organizations.create_organization(user, %{
          handle: "acctapi-org-#{System.unique_integer([:positive])}",
          name: "Account API Org"
        })

      conn =
        conn
        |> ApiTestHelpers.authenticate(user, @scopes)
        |> get("/api/accounts")

      assert %{"accounts" => accounts} = json_response(conn, 200)
      handles = Enum.map(accounts, & &1["handle"])
      assert user.account.handle in handles
      assert org_account.handle in handles
    end

    test "returns 403 when the token is missing the required scope", %{conn: conn, user: user} do
      conn =
        conn
        |> ApiTestHelpers.authenticate(user, [])
        |> get("/api/accounts")

      assert %{"error" => "insufficient_scope", "required_scope" => "account:read"} =
               json_response(conn, 403)
    end
  end
end
