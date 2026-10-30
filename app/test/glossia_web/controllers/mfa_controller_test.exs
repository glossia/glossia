defmodule GlossiaWeb.MFAControllerTest do
  use GlossiaWeb.ConnCase, async: true
  import Phoenix.LiveViewTest
  alias Glossia.Accounts.MFA
  alias Glossia.TestHelpers

  setup %{conn: conn} do
    user = TestHelpers.create_user("browser-mfa@example.test", "browser-mfa")
    {"session", token} = MFA.sign_in(user)

    %{
      user: user,
      token: token,
      conn: init_test_session(conn, %{user_id: user.id, browser_token: token})
    }
  end

  test "setup, errors, recovery disclosure and management render through real routes", %{
    conn: conn,
    user: user,
    token: token
  } do
    assert html_response(get(conn, ~p"/-/settings/security"), 200) =~
             "Set up two-factor authentication"

    assert redirected_to(post(conn, ~p"/-/settings/security/begin")) == ~p"/-/settings/security"
    setup = get(conn, ~p"/-/settings/security")
    assert html_response(setup, 200) =~ "data:image/svg+xml;base64,"
    assert get_resp_header(setup, "cache-control") == ["private, no-store"]
    assert get_resp_header(setup, "referrer-policy") == ["no-referrer"]
    failed = post(conn, ~p"/-/settings/security/confirm", %{mfa_code: "invalid"})
    assert html_response(failed, 422) =~ "That code is invalid"
    factor = MFA.pending(user, token)

    confirmed =
      post(conn, ~p"/-/settings/security/confirm", %{
        mfa_code: NimbleTOTP.verification_code(factor.secret)
      })

    html = html_response(confirmed, 200)
    assert html =~ "Save your recovery codes"
    [codes] = Regex.run(~r/<textarea[^>]*>([^<]+)<\/textarea>/, html, capture: :all_but_first)
    [first | _] = String.split(codes)
    verified = get_session(confirmed, :browser_token)
    conn = init_test_session(build_conn(), %{user_id: user.id, browser_token: verified})
    settings = html_response(get(conn, ~p"/-/settings/security"), 200)
    refute settings =~ first
    assert settings =~ "Generate new recovery codes"

    assert response(post(conn, ~p"/-/settings/security/manage", %{mfa_code: first}), 400)
    assert MFA.enabled?(user)

    disabled =
      post(conn, ~p"/-/settings/security/manage", %{mfa_code: first, operation: "disable"})

    assert redirected_to(disabled) == ~p"/-/settings/security"
    refute MFA.enabled?(user)
  end

  test "pending MFA cannot authorize devices or access dashboard; recovery completes the browser session",
       %{user: user, token: token} do
    {:ok, factor} = MFA.begin_enrollment(user, token)

    {:ok, [recovery | _], _} =
      MFA.confirm(user, token, NimbleTOTP.verification_code(factor.secret))

    pending = build_conn() |> init_test_session(%{})

    pending =
      GlossiaWeb.BrowserAuthentication.sign_in(pending, user, ~p"/oauth/device", "provider-proof")

    assert redirected_to(pending) == ~p"/auth/mfa"
    refute get_session(pending, :user_id)

    conn =
      init_test_session(build_conn(), %{
        mfa_challenge: get_session(pending, :mfa_challenge),
        return_to: ~p"/oauth/device"
      })

    assert redirected_to(get(conn, ~p"/dashboard")) == ~p"/auth/login"

    assert redirected_to(
             post(conn, ~p"/oauth/device/confirm", %{user_code: "ABCD-EFGH", decision: "approve"})
           ) == ~p"/auth/login"

    challenge = get(conn, ~p"/auth/mfa")
    assert html_response(challenge, 200) =~ "one-time-code"
    invalid = post(conn, ~p"/auth/mfa", %{mfa_code: "used-or-invalid", recovery: "true"})
    assert html_response(invalid, 422) =~ "Recovery code"
    refute html_response(invalid, 422) =~ ~s(maxlength="6")
    completed = post(conn, ~p"/auth/mfa", %{mfa_code: recovery, recovery: "true"})
    assert redirected_to(completed) == ~p"/oauth/device"
    assert get_session(completed, :user_id) == user.id
    assert get_session(completed, :organization_sso) == "provider-proof"
    assert MFA.authorized?(user, get_session(completed, :browser_token))
    logged_out = completed |> recycle() |> get(~p"/auth/logout")
    refute MFA.authorized?(user, get_session(completed, :browser_token))
    assert redirected_to(logged_out) == ~p"/"
  end

  test "factor changes invalidate already connected profile mutations", %{
    conn: conn,
    user: user,
    token: token
  } do
    {:ok, view, _} = live(conn, ~p"/-/settings/profile")
    {:ok, factor} = MFA.begin_enrollment(user, token)
    {:ok, _, _} = MFA.confirm(user, token, NimbleTOTP.verification_code(factor.secret))

    assert {:error, {:redirect, %{to: "/auth/login"}}} =
             view |> form("#profile-form", profile: %{name: "Must not save"}) |> render_submit()

    refute Glossia.Accounts.get_user(user.id).name == "Must not save"
  end

  test "impersonation cannot enroll a factor", %{conn: conn, user: user} do
    {:ok, _} = Glossia.Accounts.set_super_admin(user.id)
    conn = put_session(conn, :impersonating_from, user.id)

    assert response(post(conn, ~p"/-/settings/security/begin"), 403) =~
             "unavailable while impersonating"
  end
end
