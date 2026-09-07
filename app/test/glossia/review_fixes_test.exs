defmodule Glossia.ReviewFixesTest do
  use Glossia.DataCase, async: true

  alias Glossia.Accounts
  alias Glossia.Accounts.{Role, User, UserRole}
  alias Glossia.Organizations
  alias Glossia.Roles
  alias Glossia.Repo
  alias Glossia.TestHelpers

  # ===========================================================================
  # Fix 2: super_admin?/1 must read in memory when user_roles are preloaded,
  # and fall back to a single query only when they are not.
  # ===========================================================================

  test "super_admin?/1 issues no query when user_roles are preloaded" do
    user = TestHelpers.create_user("fix-perf-preload@test.com", "fix-perf-preload")
    assert {:ok, _user} = Accounts.set_super_admin(user.id)

    preloaded = Accounts.get_user(user.id)

    count =
      count_queries(fn ->
        assert Roles.super_admin?(preloaded)
        assert Roles.super_admin?(preloaded)
        assert Roles.super_admin?(preloaded)
      end)

    assert count == 0
  end

  test "super_admin?/1 returns false (no query) for a non-admin with preloaded roles" do
    user = TestHelpers.create_user("fix-perf-false@test.com", "fix-perf-false")
    preloaded = Accounts.get_user(user.id)

    count = count_queries(fn -> refute Roles.super_admin?(preloaded) end)

    assert count == 0
  end

  test "super_admin?/1 falls back to one query for a bare user struct" do
    user = TestHelpers.create_user("fix-perf-bare@test.com", "fix-perf-bare")
    assert {:ok, _user} = Accounts.set_super_admin(user.id)
    bare = %User{id: user.id}

    count = count_queries(fn -> assert Roles.super_admin?(bare) end)

    assert count == 1
  end

  test "super_admin?/1 falls back to a query when :role is not preloaded" do
    user = TestHelpers.create_user("fix-perf-nested@test.com", "fix-perf-nested")
    assert {:ok, _user} = Accounts.set_super_admin(user.id)

    # user_roles loaded but the nested :role is not.
    partial = Repo.get!(User, user.id) |> Repo.preload(:user_roles)

    count = count_queries(fn -> assert Roles.super_admin?(partial) end)

    assert count == 1
  end

  # ===========================================================================
  # Fix 3: instance-scoped user roles must be unique at the DB level.
  # The partial index blocks the duplicate and the changeset surfaces it.
  # ===========================================================================

  test "duplicate instance-scoped user role is rejected" do
    user = TestHelpers.create_user("fix-uniq-instance@test.com", "fix-uniq-instance")
    role = Repo.get_by!(Role, scope: "instance", name: "super_admin")

    assert {:ok, _} = insert_user_role(user.id, role.id, nil)
    assert {:error, changeset} = insert_user_role(user.id, role.id, nil)

    assert Keyword.has_key?(changeset.errors, :role_id)
  end

  test "duplicate organization-scoped user role is still rejected" do
    owner = TestHelpers.create_user("fix-uniq-org-owner@test.com", "fix-uniq-org-owner")
    member = TestHelpers.create_user("fix-uniq-org-member@test.com", "fix-uniq-org-member")

    {:ok, %{organization: organization}} =
      Organizations.create_organization(owner, %{handle: "fix-uniq-org-o", name: "O"})

    role = Repo.get_by!(Role, scope: "organization", name: "admin")

    # owner already has the admin role from create_organization, so use
    # a fresh member to prove the partial index blocks a real duplicate.
    assert {:ok, _} = insert_user_role(member.id, role.id, organization.id)
    assert {:error, changeset} = insert_user_role(member.id, role.id, organization.id)

    assert Keyword.has_key?(changeset.errors, :role_id)
  end

  test "set_instance_role/3 is idempotent" do
    user = TestHelpers.create_user("fix-idemp@test.com", "fix-idemp")

    assert :ok = Roles.set_instance_role(user, "super_admin", true)
    assert :ok = Roles.set_instance_role(user, "super_admin", true)
    assert Roles.super_admin?(Accounts.get_user(user.id))
  end

  defp insert_user_role(user_id, role_id, organization_id) do
    %UserRole{user_id: user_id, role_id: role_id, organization_id: organization_id}
    |> UserRole.changeset(%{})
    |> Repo.insert()
  end

  # ===========================================================================
  # query-counting helper
  # ===========================================================================

  defp count_queries(fun) do
    ref = make_ref()

    :telemetry.attach_many(
      ref,
      [[:glossia, :repo, :query]],
      &__MODULE__.handle/4,
      self()
    )

    fun.()
    :telemetry.detach(ref)

    Process.delete(:query_count) || 0
  end

  def handle(_event, _measurements, _metadata, pid) do
    if pid == self() do
      Process.put(:query_count, (Process.get(:query_count) || 0) + 1)
    end
  end
end
