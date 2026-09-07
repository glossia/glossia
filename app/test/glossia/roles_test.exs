defmodule Glossia.RolesTest do
  use Glossia.DataCase, async: true

  alias Glossia.Accounts
  alias Glossia.Accounts.Organization
  alias Glossia.Organizations
  alias Glossia.Repo
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

  describe "list_user_organizations/1" do
    test "returns the organizations a user is a member of, sorted by name" do
      user = TestHelpers.create_user("list-orgs-user@test.com", "list-orgs-user")

      {:ok, %{organization: zeta}} =
        Organizations.create_organization(user, %{handle: "list-orgs-zeta", name: "Zeta"})

      {:ok, %{organization: alpha}} =
        Organizations.create_organization(user, %{handle: "list-orgs-alpha", name: "Alpha"})

      # The two organizations created above plus the user's personal org from
      # ensure_personal_organization!/1.
      organizations = Roles.list_user_organizations(user)
      names = Enum.map(organizations, & &1.name)

      assert alpha.name in names
      assert zeta.name in names
      assert names == Enum.sort(names)
      assert length(names) >= 3

      # Sanity check: the returned records are real Organizations.
      assert Enum.all?(organizations, &match?(%Organization{}, &1))
      assert Repo.all(Organization) |> length() >= 3
    end

    test "returns an empty list when the user has no organization memberships" do
      user = TestHelpers.create_user("list-orgs-empty@test.com", "list-orgs-empty")

      # Strip the personal org created by ensure_personal_organization!/1 so
      # the user really has no memberships left.
      Repo.delete_all(Ecto.assoc(user, :user_roles))

      assert Roles.list_user_organizations(user) == []
    end
  end
end
