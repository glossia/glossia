defmodule GlossiaWeb.Internal.TemporaryAccessGrantControllerTest do
  use GlossiaWeb.ConnCase, async: true
  use Mimic

  @endpoint GlossiaWeb.BabelInternalEndpoint

  alias Glossia.BabelWorkloadIdentity
  alias Glossia.Organizations
  alias Glossia.TestHelpers

  setup :set_mimic_from_context

  test "records a verified, time-bounded access grant for an existing Glossia user", %{conn: conn} do
    owner =
      TestHelpers.create_user("owner-#{System.unique_integer([:positive])}@example.com", "owner")

    recipient =
      TestHelpers.create_user(
        "support-#{System.unique_integer([:positive])}@glossia.ai",
        "support"
      )

    organization = Organizations.get_organization_for_account(owner.account)
    allow_babel()

    conn =
      conn
      |> put_req_header("authorization", "Bearer valid-token")
      |> post(babel_path(), %{
        "organization_id" => organization.id,
        "email" => recipient.email,
        "duration_minutes" => 30,
        "requested_by_email" => "operator@glossia.ai",
        "requested_by_pomerium_id" => "google/operator",
        "reason" => "Investigate the translation configuration reported by support."
      })

    response = json_response(conn, 201)

    assert response["account_handle"] == owner.account.handle
    assert response["recipient_email"] == recipient.email
    assert grant_id = response["temporary_access_grant_id"]

    assert is_binary(grant_id)
  end

  test "rejects a grant request for an external recipient", %{conn: conn} do
    owner =
      TestHelpers.create_user("owner-#{System.unique_integer([:positive])}@example.com", "owner")

    organization = Organizations.get_organization_for_account(owner.account)
    allow_babel()

    conn =
      conn
      |> put_req_header("authorization", "Bearer valid-token")
      |> post(babel_path(), %{
        "organization_id" => organization.id,
        "email" => "not-a-user@example.com",
        "duration_minutes" => 30,
        "requested_by_email" => "operator@glossia.ai",
        "requested_by_pomerium_id" => "google/operator",
        "reason" => "Investigate the translation configuration reported by support."
      })

    assert %{"error" => "recipient_or_organization_not_found"} = json_response(conn, 404)
  end

  test "creates and transfers a claimable organization through the private Babel listener", %{
    conn: conn
  } do
    recipient =
      TestHelpers.create_user(
        "maintainer-#{System.unique_integer([:positive])}@example.com",
        "maintainer"
      )

    handle = "omarchy-#{System.unique_integer([:positive])}"
    allow_babel()

    conn =
      conn
      |> put_req_header("authorization", "Bearer valid-token")
      |> post(claimable_path(), %{
        "handle" => handle,
        "name" => "Omarchy",
        "requested_by_email" => "operator@glossia.ai",
        "requested_by_pomerium_id" => "google/operator"
      })

    assert %{"claimable" => true, "handle" => ^handle, "visibility" => "public"} =
             json_response(conn, 201)

    conn =
      build_conn()
      |> put_req_header("authorization", "Bearer valid-token")
      |> post("#{claimable_path()}/#{handle}/transfer", %{
        "email" => recipient.email,
        "requested_by_email" => "operator@glossia.ai",
        "requested_by_pomerium_id" => "google/operator"
      })

    assert %{"claimable" => false, "claimed_by" => claimed_by} = json_response(conn, 200)
    assert claimed_by == recipient.email

    organization =
      handle
      |> Glossia.Accounts.get_account_by_handle()
      |> Organizations.get_organization_for_account()

    assert %{role: "admin"} = Organizations.get_membership(organization, recipient)
  end

  defp allow_babel do
    stub(BabelWorkloadIdentity, :verify, fn "valid-token" ->
      {:ok, %{namespace: "babel", name: "babel"}}
    end)
  end

  defp babel_path,
    do: "https://babel-internal.glossia.ai/api/internal/babel/temporary-access-grants"

  defp claimable_path,
    do: "https://babel-internal.glossia.ai/api/internal/babel/claimable-organizations"
end
