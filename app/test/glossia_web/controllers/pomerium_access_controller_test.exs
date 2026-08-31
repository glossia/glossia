defmodule GlossiaWeb.PomeriumAccessControllerTest do
  use GlossiaWeb.ConnCase, async: false
  use Mimic

  alias Glossia.Organizations
  alias Glossia.Pomerium
  alias Glossia.TemporaryAccess
  alias Glossia.TestHelpers

  setup :set_mimic_global

  test "activates a temporary grant only after Pomerium verifies the recipient", %{conn: conn} do
    owner =
      TestHelpers.create_user("owner-#{System.unique_integer([:positive])}@example.com", "owner")

    recipient =
      TestHelpers.create_user(
        "support-#{System.unique_integer([:positive])}@glossia.ai",
        "support"
      )

    organization = Organizations.get_organization_for_account(owner.account)
    assert {:ok, _grant} = grant(organization, recipient)

    stub(Pomerium, :identity_from_assertion, fn "verified-assertion" ->
      {:ok, %{email: recipient.email, name: "Support", subject: "google/support"}}
    end)

    conn =
      conn
      |> put_req_header("x-pomerium-jwt-assertion", "verified-assertion")
      |> get("https://access.glossia.ai/auth/pomerium?account=#{owner.account.handle}")

    assert redirected_to(conn) == "/#{owner.account.handle}"
    assert get_session(conn, :user_id) == recipient.id

    access = get_session(conn, :pomerium_access)
    assert access["user_id"] == recipient.id
    assert grant_id = access["grant_id"]

    assert is_binary(grant_id)
  end

  test "does not accept a forwarded header that fails Pomerium verification", %{conn: conn} do
    stub(Pomerium, :identity_from_assertion, fn _assertion -> {:error, :invalid_assertion} end)

    conn =
      conn
      |> put_req_header("x-pomerium-jwt-assertion", "forged-assertion")
      |> get("https://access.glossia.ai/auth/pomerium?account=unknown")

    assert html_response(conn, 404)
  end

  defp grant(organization, recipient) do
    TemporaryAccess.grant(organization, recipient, %{
      "duration_minutes" => 30,
      "requested_by_email" => "operator@glossia.ai",
      "requested_by_pomerium_id" => "google/operator",
      "reason" => "Investigate the translation configuration reported by support."
    })
  end
end
