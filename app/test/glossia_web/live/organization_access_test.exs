defmodule GlossiaWeb.OrganizationAccessTest do
  use GlossiaWeb.ConnCase, async: true
  import Phoenix.LiveViewTest
  alias Glossia.{OrganizationAuthentication, Organizations, TestHelpers}

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
  end

  test "whole permission areas can be selected, persisted, and cleared", %{
    conn: conn,
    account: account,
    organization: organization,
    member: member
  } do
    {:ok, view, _} = live(conn, ~p"/#{account.handle}/-/members/#{member.id}/permissions")
    render_hook(view, "set_group:project", %{"checked" => true})
    render_hook(view, "save", %{})
    assert "project:write" in Organizations.get_membership(organization, member).scopes
    render_hook(view, "set_group:project", %{"checked" => false})
    render_hook(view, "save", %{})
    refute "project:read" in Organizations.get_membership(organization, member).scopes
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

  test "non-administrators cannot edit authentication or permissions", %{
    conn: conn,
    account: account,
    member: member
  } do
    conn = init_test_session(conn, %{user_id: member.id})

    assert_raise Ecto.NoResultsError, fn ->
      live(conn, ~p"/#{account.handle}/-/settings/authentication")
    end

    assert_raise Ecto.NoResultsError, fn ->
      live(conn, ~p"/#{account.handle}/-/members/#{member.id}/permissions")
    end
  end
end
