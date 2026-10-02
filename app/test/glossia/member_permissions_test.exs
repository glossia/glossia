defmodule Glossia.MemberPermissionsTest do
  use Glossia.DataCase, async: true
  alias Glossia.{Authz, MemberPermissions, Organizations, TestHelpers}

  setup do
    admin = TestHelpers.create_user("admin@example.test", "admin")
    member = TestHelpers.create_user("member@example.test", "member")

    {:ok, %{organization: organization, account: account}} =
      Organizations.create_organization(admin, %{
        handle: "permissions-#{System.unique_integer([:positive])}"
      })

    {:ok, _} = Organizations.add_member(organization, member)
    %{admin: admin, member: member, organization: organization, account: account}
  end

  test "permission groups exclude instance and personal-user scopes" do
    refute "admin:write" in MemberPermissions.available_scopes()
    refute "ops:read" in MemberPermissions.available_scopes()

    for scope <-
          ~w(members:write api_credentials:read api_credentials:write llm_model:write organization:delete),
        do: refute(scope in MemberPermissions.available_scopes())

    refute "user:write" in MemberPermissions.available_scopes()
    assert {"project", scopes} = List.keyfind(MemberPermissions.groups(), "project", 0)
    assert "project:write" in scopes
  end

  test "grants are organization-scoped and token scopes still constrain them", context do
    %{admin: admin, member: member, organization: organization, account: account} = context

    assert {:ok, _} =
             MemberPermissions.update(organization, admin, member, [
               "project:read",
               "project:write"
             ])

    assert Authz.authorize?(:project_write, member, account)

    assert {:error, :insufficient_scope, "project:write"} =
             Authz.authorize(:project_write, member, account, scopes: ["project:read"])

    refute Authz.authorize?(:members_write, member, account)
    other = TestHelpers.create_user("other@example.test", "other")
    refute Authz.authorize?(:project_write, member, other.account)
    assert Authz.authorize?(:user_write, member, member)
  end

  test "only administrators can assign valid scopes or edit organization members", context do
    %{admin: admin, member: member, organization: organization} = context

    assert {:error, :unauthorized} =
             MemberPermissions.update(organization, member, member, ["project:write"])

    assert {:error, :invalid_scopes} =
             MemberPermissions.update(organization, admin, member, ["admin:write"])

    assert {:error, :administrator} = MemberPermissions.update(organization, admin, admin, [])

    assert {:error, :invalid_scopes} =
             MemberPermissions.update(organization, admin, member, ["members:write"])

    assert {:error, :invalid_scopes} =
             MemberPermissions.update(organization, admin, member, ["api_credentials:write"])

    outsider = TestHelpers.create_user("outsider@example.test", "outsider")
    assert {:error, :not_a_member} = MemberPermissions.update(organization, admin, outsider, [])
  end

  test "clearing permissions revokes access while existing roles remain compatible", context do
    %{admin: admin, member: member, organization: organization, account: account} = context
    assert {:ok, membership} = MemberPermissions.update(organization, admin, member, [])
    refute Authz.authorize?(:project_read, member, account)
    membership |> Ecto.Changeset.change(scopes: nil) |> Glossia.Repo.update!()
    assert Authz.authorize?(:translation_write, member, account)
    assert Authz.authorize?(:project_admin, admin, account)
  end
end
