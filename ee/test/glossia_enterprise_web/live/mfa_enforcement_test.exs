defmodule GlossiaEnterpriseWeb.MFAEnforcementTest do
  use GlossiaWeb.ConnCase, async: true
  import Phoenix.LiveViewTest
  alias Glossia.{Organizations, TestHelpers}
  alias Glossia.Accounts.MFA
  alias GlossiaEnterprise.OrganizationAuthentication, as: Authentication

  test "only an enrolled admin can enforce; existing HTTP and connected sessions must enroll", %{
    conn: conn
  } do
    admin = TestHelpers.create_user("mfa-admin@example.test", "mfa-admin")
    member = TestHelpers.create_user("mfa-member@example.test", "mfa-member")

    {:ok, %{organization: org, account: account}} =
      Organizations.create_organization(admin, %{
        handle: "mfa-#{System.unique_integer([:positive])}"
      })

    {:ok, _} = Organizations.add_member(org, member)
    {"session", admin_token} = MFA.sign_in(admin)
    {"session", member_token} = MFA.sign_in(member)
    member_conn = init_test_session(conn, %{user_id: member.id, browser_token: member_token})
    {:ok, open, _} = live(member_conn, ~p"/#{account.handle}")

    assert {:error, :mfa_required} =
             Authentication.set_mfa_enforcement(org, admin, true, admin_token)

    {:ok, factor} = MFA.begin_enrollment(admin, admin_token)

    {:ok, _, admin_token} =
      MFA.confirm(admin, admin_token, NimbleTOTP.verification_code(factor.secret))

    assert {:error, :mfa_required} =
             Authentication.set_mfa_enforcement(org, member, true, member_token)

    admin_conn = init_test_session(conn, %{user_id: admin.id, browser_token: admin_token})
    {:ok, settings, _} = live(admin_conn, ~p"/#{account.handle}/-/settings/authentication")
    assert has_element?(settings, "#mfa-enforcement", "Enforce MFA")
    settings |> element("#mfa-enforcement") |> render_click()
    assert Authentication.mfa_enforced?(org)
    assert redirected_to(get(member_conn, ~p"/#{account.handle}")) == ~p"/-/settings/security"

    assert html_response(get(member_conn, ~p"/-/settings/security"), 200) =~
             "Set up two-factor authentication"

    assert {:error, {:redirect, %{to: "/-/settings/security"}}} = render_hook(open, "refresh")
    assert Authentication.session_authorized?(account, nil, nil)
    assert Authentication.session_authorized?(account, admin, nil)

    {:ok, member_factor} = MFA.begin_enrollment(member, member_token)

    {:ok, [recovery | _], verified} =
      MFA.confirm(member, member_token, NimbleTOTP.verification_code(member_factor.secret))

    member_conn = init_test_session(conn, %{user_id: member.id, browser_token: verified})
    assert html_response(get(member_conn, ~p"/#{account.handle}"), 200)
    {:ok, [], replacement} = MFA.manage(member, verified, recovery, true, :disable)
    member_conn = init_test_session(conn, %{user_id: member.id, browser_token: replacement})
    assert redirected_to(get(member_conn, ~p"/#{account.handle}")) == ~p"/-/settings/security"
    assert Authentication.mfa_enforced?(org)

    %{rows: events} = GlossiaEnterprise.Audit.list_events(account, admin)

    for {actor, name} <- [
          {admin, "user.mfa_enabled"},
          {admin, "organization.mfa_enforcement_updated"},
          {member, "user.mfa_enabled"},
          {member, "user.mfa_disabled"}
        ] do
      assert Enum.any?(events, &(&1.user_id == actor.id and &1.name == name))
    end

    assert {:ok, false} = Authentication.set_mfa_enforcement(org, admin, false, admin_token)
    assert Authentication.session_authorized?(account, member, nil)
  end
end
