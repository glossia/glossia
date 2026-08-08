defmodule Glossia.Accounts.UserRoleTest do
  use Glossia.DataCase, async: true

  alias Glossia.Accounts
  alias Glossia.Accounts.{Role, UserRole}
  alias Glossia.Organizations
  alias Glossia.Roles
  alias Glossia.Repo
  alias Glossia.TestHelpers

  describe "changeset/2" do
    test "is valid for the four required fields" do
      user = TestHelpers.create_user("user-role-cs@test.com", "user-role-cs")
      role = Repo.get_by!(Role, scope: "instance", name: "super_admin")

      changeset = %UserRole{user_id: user.id, role_id: role.id} |> UserRole.changeset(%{})

      assert changeset.valid?
    end
  end

  describe "associations" do
    test "User has many user_roles, and the inverse resolves to the original User" do
      user = TestHelpers.create_user("user-role-user@test.com", "user-role-user")
      assert {:ok, _user} = Accounts.set_super_admin(user.id)

      loaded = Repo.preload(user, user_roles: :user)
      # Two user_roles for this user: the instance-scoped super_admin and
      # the org-scoped admin (the personal org created by
      # ensure_personal_organization!/1 also writes a user_role).
      assert length(loaded.user_roles) == 2

      assert Enum.all?(loaded.user_roles, &(&1.user_id == user.id))
      assert Enum.all?(loaded.user_roles, &Ecto.assoc_loaded?(&1.user))
      assert Enum.all?(loaded.user_roles, &(&1.user.id == user.id))
    end

    test "Organization has many user_roles scoped to that organization only" do
      owner = TestHelpers.create_user("user-role-org-owner@test.com", "user-role-org-owner")
      other = TestHelpers.create_user("user-role-org-other@test.com", "user-role-org-other")

      {:ok, %{organization: organization}} =
        Organizations.create_organization(owner, %{handle: "user-role-org", name: "UserRole Org"})

      # An org-scoped user_role for the owner is created by
      # Organizations.create_organization/2. Adding a second user gives
      # the org two members.
      {:ok, _membership} = Organizations.add_member(organization, other, "member")

      loaded = Repo.preload(organization, user_roles: :user)
      assert length(loaded.user_roles) == 2

      user_ids = Enum.map(loaded.user_roles, & &1.user_id) |> Enum.sort()
      assert user_ids == Enum.sort([owner.id, other.id])

      # The preload of :user should be wired up the other way too.
      assert Enum.all?(loaded.user_roles, &Ecto.assoc_loaded?(&1.user))
    end

    test "Role has many user_roles scoped to that role only" do
      first = TestHelpers.create_user("user-role-role-first@test.com", "user-role-role-first")
      second = TestHelpers.create_user("user-role-role-second@test.com", "user-role-role-second")

      assert {:ok, _first} = Accounts.set_super_admin(first.id)
      assert {:ok, _second} = Accounts.set_super_admin(second.id)

      role = Repo.get_by!(Role, scope: "instance", name: "super_admin")
      loaded = Repo.preload(role, :user_roles)
      user_ids = Enum.map(loaded.user_roles, & &1.user_id) |> Enum.sort()

      assert first.id in user_ids
      assert second.id in user_ids
    end
  end

  describe "Roles.super_admin?/1 with the new association" do
    test "reads the instance super_admin role from preloaded user_roles" do
      user = TestHelpers.create_user("user-role-preload@test.com", "user-role-preload")
      assert {:ok, _user} = Accounts.set_super_admin(user.id)

      loaded = Accounts.get_user(user.id)
      assert Roles.super_admin?(loaded)
    end

    test "returns false for a non-admin with preloaded user_roles" do
      user = TestHelpers.create_user("user-role-noop@test.com", "user-role-noop")
      loaded = Accounts.get_user(user.id)

      refute Roles.super_admin?(loaded)
    end
  end
end
