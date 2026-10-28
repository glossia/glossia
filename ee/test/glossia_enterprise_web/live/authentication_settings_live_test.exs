defmodule GlossiaEnterpriseWeb.AuthenticationSettingsLiveTest do
  use GlossiaWeb.ConnCase, async: true
  import Phoenix.LiveViewTest
  alias Glossia.{Organizations, TestHelpers}
  alias GlossiaEnterprise.OrganizationAuthentication

  setup %{conn: conn} do
    admin = TestHelpers.create_user("admin@example.test", "admin")
    member = TestHelpers.create_user("member@example.test", "member")

    {:ok, %{organization: organization, account: account}} =
      Organizations.create_organization(admin, %{
        handle: "access-#{System.unique_integer([:positive])}"
      })

    {:ok, _} = Organizations.add_member(organization, member)

    %{
      conn: init_test_session(conn, %{user_id: admin.id}),
      admin: admin,
      member: member,
      organization: organization,
      account: account
    }
  end

  test "saves provider configuration and displays the verification record", %{
    conn: conn,
    account: account,
    organization: organization
  } do
    {:ok, view, _} = live(conn, ~p"/#{account.handle}/-/settings/authentication")
    assert has_element?(view, "#account-section-organization[data-open]")

    assert has_element?(
             view,
             ~s(#account-section-organization a[href="#{~p"/#{account.handle}/-/settings/authentication"}"] [data-selected])
           )

    refute has_element?(view, "#account-section-enterprise")
    refute has_element?(view, "#organization-settings-navigation[data-open]")
    refute has_element?(view, "#organization-settings-navigation [data-selected]")
    refute has_element?(view, "#authentication-settings > .noora-badge", "Enterprise")
    render_hook(view, "provider", %{"value" => "google"})

    view
    |> form("#organization-authentication-form",
      authentication: %{
        auth_provider: "google",
        auth_domain: "team-#{System.unique_integer([:positive])}.test"
      }
    )
    |> render_submit()

    saved = Organizations.get_organization(organization.id)
    assert render(view) =~ OrganizationAuthentication.record_value(saved)
    assert render(view) =~ "Awaiting verification"
    assert render(view) =~ "DNS TXT record"
    assert has_element?(view, "#google-workspace-setup")
    refute has_element?(view, ~s(input[name="callback"]))

    {:ok, reloaded, _} = live(conn, ~p"/#{account.handle}/-/settings/authentication")
    assert has_element?(reloaded, "#google-workspace-setup")
  end

  test "Google setup guidance follows the selected provider and only Okta shows a redirect address",
       %{
         conn: conn,
         account: account
       } do
    {:ok, view, _} = live(conn, ~p"/#{account.handle}/-/settings/authentication")
    refute has_element?(view, "#google-workspace-setup")
    refute has_element?(view, ~s(input[name="callback"]))

    render_hook(view, "provider", %{"value" => "google"})
    assert has_element?(view, "#google-workspace-setup", "Glossia manages the Google connection")
    assert has_element?(view, "#google-workspace-setup ol li", "TXT record")
    assert has_element?(view, "#google-workspace-setup", "Manage third-party app access")

    assert has_element?(
             view,
             ~s(#google-workspace-setup a[href="#{~p"/docs/how-to/organization-sign-in"}"])
           )

    refute has_element?(view, ~s(input[name="callback"]))

    render_hook(view, "provider", %{"value" => "okta"})
    refute has_element?(view, "#google-workspace-setup")

    assert has_element?(
             view,
             ~s(input[name="callback"][value="#{OrganizationAuthentication.callback_url()}"])
           )

    render_hook(view, "provider", %{"value" => "disabled"})
    refute has_element?(view, "#google-workspace-setup")
    refute has_element?(view, ~s(input[name="callback"]))
  end

  test "saving an invalid form never exposes the saved client secret", %{
    conn: conn,
    account: account,
    organization: organization,
    admin: admin
  } do
    secret = "private-client-secret"

    {:ok, _} =
      OrganizationAuthentication.save(organization, admin, %{
        "auth_provider" => "okta",
        "auth_domain" => "secret-#{System.unique_integer([:positive])}.test",
        "auth_issuer" => "https://team.okta.com",
        "auth_client_id" => "client",
        "auth_client_secret" => secret
      })

    {:ok, view, html} = live(conn, ~p"/#{account.handle}/-/settings/authentication")
    refute html =~ secret

    html =
      view
      |> form("#organization-authentication-form",
        authentication: %{auth_domain: "invalid", auth_client_secret: ""}
      )
      |> render_submit()

    refute html =~ secret
    assert html =~ "has invalid format"
  end

  test "custom OAuth2 settings persist and endpoint errors keep the form usable without secrets",
       %{conn: conn, account: account, organization: organization} do
    {:ok, view, _} = live(conn, ~p"/#{account.handle}/-/settings/authentication")
    render_hook(view, "provider", %{"value" => "oauth2"})

    params = %{
      auth_provider: "oauth2",
      auth_domain: "custom-#{System.unique_integer([:positive])}.test",
      auth_issuer: "https://id.example.com",
      auth_authorize_url: "https://id.example.com/authorize",
      auth_token_url: "http://localhost/token",
      auth_userinfo_url: "https://id.example.com/userinfo",
      auth_client_id: "client",
      auth_client_secret: "never-render-this-secret"
    }

    html =
      view |> form("#organization-authentication-form", authentication: params) |> render_submit()

    assert html =~ "must be an HTTPS URL"
    refute html =~ "never-render-this-secret"
    assert has_element?(view, ~s(input[name="authentication[auth_domain]"]))

    view
    |> form("#organization-authentication-form",
      authentication: Map.put(params, :auth_token_url, "https://id.example.com/token")
    )
    |> render_submit()

    saved = Organizations.get_organization(organization.id)
    assert saved.auth_provider == "oauth2"
    assert saved.auth_client_secret == "never-render-this-secret"
    {:ok, reloaded, html} = live(conn, ~p"/#{account.handle}/-/settings/authentication")
    assert has_element?(reloaded, ~s(input[value="https://id.example.com/token"]))
    refute html =~ "never-render-this-secret"
  end

  test "non-administrators cannot edit authentication", %{
    conn: conn,
    account: account,
    member: member
  } do
    conn = init_test_session(conn, %{user_id: member.id})

    assert_raise Ecto.NoResultsError, fn ->
      live(conn, ~p"/#{account.handle}/-/settings/authentication")
    end
  end

  test "SCIM tokens are shown once, survive reload only as names, and can be revoked", %{
    conn: conn,
    account: account
  } do
    {:ok, view, _} = live(conn, ~p"/#{account.handle}/-/settings/authentication")
    assert has_element?(view, "[data-part=empty-tokens]", "No provisioning tokens")
    view |> form("#scim-token-form", scim: %{name: "Okta production"}) |> render_submit()
    assert has_element?(view, "#scim-token-secret")

    [plaintext] =
      view
      |> element("input[name=scim_token]")
      |> render()
      |> LazyHTML.from_fragment()
      |> LazyHTML.query("input")
      |> LazyHTML.attribute("value")

    assert {:ok, organization} = GlossiaEnterprise.SCIM.authenticate_token(plaintext)
    assert organization.account_id == account.id
    refute has_element?(view, "[data-part=empty-tokens]")
    view |> element("button", "I have copied the token") |> render_click()
    refute has_element?(view, "#scim-token-secret")

    {:ok, reloaded, html} = live(conn, ~p"/#{account.handle}/-/settings/authentication")
    refute html =~ plaintext
    assert has_element?(reloaded, "input[value='Okta production']")
    reloaded |> element("button", "Revoke token") |> render_click()
    assert {:error, :invalid_token} = GlossiaEnterprise.SCIM.authenticate_token(plaintext)
    assert has_element?(reloaded, "[data-part=empty-tokens]")
  end

  test "SSO enforcement requires a tested administrator session and gates existing browser sessions",
       %{
         conn: conn,
         organization: organization,
         account: account,
         admin: admin,
         member: member
       } do
    {:ok, organization} =
      OrganizationAuthentication.save(organization, admin, %{
        "auth_provider" => "google",
        "auth_domain" => "sso-#{System.unique_integer([:positive])}.test"
      })

    {:ok, organization} =
      OrganizationAuthentication.verify(organization, admin, fn _ ->
        {:ok, [OrganizationAuthentication.record_value(organization)]}
      end)

    {:ok, ordinary, _} = live(conn, ~p"/#{account.handle}/-/settings/authentication")
    ordinary |> element("#sso-enforcement") |> render_click()
    refute OrganizationAuthentication.enforced?(organization)
    assert render(ordinary) =~ "sign in with this organization"

    proof = OrganizationAuthentication.session_proof(organization, admin)
    sso_conn = init_test_session(conn, %{user_id: admin.id, organization_sso: proof})
    {:ok, tested, _} = live(sso_conn, ~p"/#{account.handle}/-/settings/authentication")
    tested |> element("#sso-enforcement") |> render_click()
    assert OrganizationAuthentication.enforced?(organization)
    assert has_element?(tested, "#sso-enforcement", "Disable enforcement")

    assert {:error, {:redirect, %{to: "/auth/login"}}} =
             live(conn, ~p"/#{account.handle}/-/settings/authentication")

    assert {:error, :enforcement_enabled} =
             OrganizationAuthentication.save(organization, admin, %{"auth_provider" => ""})

    refute OrganizationAuthentication.session_authorized?(account, member, proof)
    assert OrganizationAuthentication.session_authorized?(admin.account, admin, nil)
    assert OrganizationAuthentication.session_authorized?(account, nil, nil)

    # The socket mounted before enforcement must also reauthenticate on its next event.
    assert {:error, {:redirect, %{to: "/auth/login"}}} =
             ordinary |> element("#sso-enforcement") |> render_click()

    tested |> element("#sso-enforcement") |> render_click()
    refute OrganizationAuthentication.enforced?(organization)
    assert {:ok, _, _} = live(conn, ~p"/#{account.handle}/-/settings/authentication")
  end

  test "enforcement redirects open sockets before server-originated updates", %{
    conn: conn,
    organization: organization,
    account: account,
    admin: admin
  } do
    {:ok, saved} =
      OrganizationAuthentication.save(organization, admin, %{
        "auth_provider" => "google",
        "auth_domain" => "push-#{System.unique_integer([:positive])}.test"
      })

    {:ok, verified} =
      OrganizationAuthentication.verify(saved, admin, fn _ ->
        {:ok, [OrganizationAuthentication.record_value(saved)]}
      end)

    proof = OrganizationAuthentication.session_proof(verified, admin)
    sso_conn = init_test_session(conn, %{user_id: admin.id, organization_sso: proof})
    {:ok, ordinary, _} = live(conn, ~p"/#{account.handle}")
    {:ok, tested, _} = live(sso_conn, ~p"/#{account.handle}")
    assert {:ok, true} = OrganizationAuthentication.set_enforcement(verified, admin, true, proof)

    send(ordinary.pid, {:setup_event, %{message: "private server update"}})
    assert_redirect(ordinary, ~p"/auth/login")

    send(tested.pid, {:setup_event, %{message: "authorized server update"}})
    assert render(tested) =~ account.handle
  end

  test "the Enterprise backend follows the user's locale in connected LiveViews", %{
    conn: conn,
    account: account,
    admin: admin
  } do
    admin |> Ecto.Changeset.change(locale: "es") |> Glossia.Repo.update!()
    {:ok, view, _} = live(conn, ~p"/#{account.handle}/-/settings/authentication")
    assert render(view) =~ "Autenticación"
  end
end
