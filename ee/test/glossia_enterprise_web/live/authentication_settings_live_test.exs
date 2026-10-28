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
