defmodule Glossia.RolesTest do
  use Glossia.DataCase, async: true

  alias Glossia.Accounts
  alias Glossia.Organizations
  alias Glossia.Roles
  alias Glossia.TestHelpers

  test "assigns instance and organization roles independently" do
    user = TestHelpers.create_user("roles-user@test.com", "roles-user")
    member = TestHelpers.create_user("roles-member@test.com", "roles-member")

    refute Roles.super_admin?(user)
    assert {:ok, _user} = Accounts.set_super_admin(user.id)
    assert Roles.super_admin?(user)

    {:ok, %{organization: organization}} =
      Organizations.create_organization(user, %{handle: "roles-organization", name: "Roles"})

    assert Roles.has_organization_role?(user, organization, "admin")
    refute Roles.organization_member?(member, organization)

    assert {:ok, _membership} = Organizations.add_member(organization, member, "member")
    assert Roles.has_organization_role?(member, organization, "member")

    assert {:ok, _membership} = Organizations.update_member_role(organization, member, "linguist")
    assert Roles.has_organization_role?(member, organization, "linguist")
    refute Roles.has_organization_role?(member, organization, "member")
  end
end
