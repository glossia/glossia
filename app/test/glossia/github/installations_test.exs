defmodule Glossia.Github.InstallationsTest do
  use Glossia.DataCase, async: true

  alias Glossia.Accounts.{Account, Organization, OrganizationMembership}
  alias Glossia.Github.Installations
  alias Glossia.Repo
  alias Glossia.TestHelpers

  defp create_organization_account!(attrs) do
    {:ok, account} =
      %Account{}
      |> Account.changeset(%{
        handle: attrs[:handle] || "org-#{System.unique_integer([:positive])}",
        type: "organization",
        has_access: true
      })
      |> Repo.insert()

    {:ok, organization} =
      %Organization{}
      |> Organization.changeset(%{
        name: attrs[:name] || "Organization"
      })
      |> Ecto.Changeset.put_assoc(:account, account)
      |> Repo.insert()

    %{organization | account: account}
  end

  defp add_member!(organization, user, role \\ "member") do
    {:ok, membership} =
      %OrganizationMembership{}
      |> OrganizationMembership.changeset(%{role: role})
      |> Ecto.Changeset.put_change(:organization_id, organization.id)
      |> Ecto.Changeset.put_change(:user_id, user.id)
      |> Repo.insert()

    membership
  end

  defp installation_attrs(id, login) do
    %{
      github_installation_id: id,
      github_account_login: login,
      github_account_type: "Organization",
      github_account_id: id + 1000
    }
  end

  test "create_installation/2 persists a GitHub installation" do
    user = TestHelpers.create_user("gh-install-create@test.com", "gh-install-create")

    assert {:ok, installation} =
             Installations.create_installation(user.account, installation_attrs(101, "acme"))

    assert installation.account_id == user.account.id
    assert installation.github_installation_id == 101
    assert installation.github_account_login == "acme"
  end

  test "get_installation_for_account/1 returns the latest installation" do
    user = TestHelpers.create_user("gh-install-latest@test.com", "gh-install-latest")

    {:ok, older} =
      Installations.create_installation(user.account, installation_attrs(201, "older"))

    older_timestamp = DateTime.add(older.inserted_at, -60, :second)

    from(i in Glossia.Accounts.GithubInstallation, where: i.id == ^older.id)
    |> Repo.update_all(set: [inserted_at: older_timestamp, updated_at: older_timestamp])

    {:ok, newer} =
      Installations.create_installation(user.account, installation_attrs(202, "newer"))

    assert Installations.get_installation_for_account(user.account.id).id == newer.id
    assert older.id != newer.id
  end

  test "list_installations_for_account/1 returns all installations for the account" do
    user = TestHelpers.create_user("gh-install-list@test.com", "gh-install-list")

    {:ok, first} =
      Installations.create_installation(user.account, installation_attrs(301, "first"))

    {:ok, second} =
      Installations.create_installation(user.account, installation_attrs(302, "second"))

    ids =
      user.account.id
      |> Installations.list_installations_for_account()
      |> Enum.map(& &1.id)

    assert Enum.sort(ids) == Enum.sort([first.id, second.id])
  end

  test "list_installations_for_user/1 returns personal and organization installations, excluding suspended ones" do
    user = TestHelpers.create_user("gh-install-user@test.com", "gh-install-user")

    organization =
      create_organization_account!(
        name: "Org",
        handle: "org-#{System.unique_integer([:positive])}"
      )

    add_member!(organization, user)

    {:ok, personal} =
      Installations.create_installation(user.account, installation_attrs(401, "personal"))

    {:ok, active_org} =
      Installations.create_installation(
        organization.account,
        installation_attrs(402, "active-org")
      )

    {:ok, suspended_org} =
      Installations.create_installation(
        organization.account,
        installation_attrs(403, "suspended-org")
      )

    {:ok, _} = Installations.suspend_installation(suspended_org)

    returned_ids =
      user
      |> Installations.list_installations_for_user()
      |> Enum.map(& &1.id)

    assert personal.id in returned_ids
    assert active_org.id in returned_ids
    refute suspended_org.id in returned_ids
  end

  test "get_installation_by_github_id/1 fetches by external id" do
    user = TestHelpers.create_user("gh-install-external@test.com", "gh-install-external")

    {:ok, installation} =
      Installations.create_installation(user.account, installation_attrs(501, "external"))

    assert Installations.get_installation_by_github_id(501).id == installation.id
  end

  test "delete_installation/2 deletes and emits an event when actor is provided" do
    user = TestHelpers.create_user("gh-install-delete@test.com", "gh-install-delete")

    {:ok, installation} =
      Installations.create_installation(user.account, installation_attrs(601, "delete-me"))

    assert {:ok, deleted} =
             TestHelpers.expect_event(
               "github_installation.deleted",
               fn ->
                 Installations.delete_installation(installation, actor: user, via: :dashboard)
               end,
               %{
                 :account_id => user.account.id,
                 :user_id => user.id,
                 {:opt, :via} => :dashboard,
                 {:opt, :resource_type} => "github_installation"
               }
             )

    assert deleted.id == installation.id
    refute Repo.get_by(Glossia.Accounts.GithubInstallation, id: installation.id)
  end

  test "delete_installation_by_github_id/1 deletes existing installations and returns not_found otherwise" do
    user = TestHelpers.create_user("gh-install-delete-by-id@test.com", "gh-install-delete-by-id")

    {:ok, installation} =
      Installations.create_installation(user.account, installation_attrs(701, "delete-by-id"))

    assert {:ok, deleted} = Installations.delete_installation_by_github_id(701)
    assert deleted.id == installation.id
    assert {:error, :not_found} = Installations.delete_installation_by_github_id(999_999)
  end

  test "suspend_installation/1 and unsuspend_installation/1 toggle suspended_at" do
    user = TestHelpers.create_user("gh-install-suspend@test.com", "gh-install-suspend")

    {:ok, installation} =
      Installations.create_installation(user.account, installation_attrs(801, "suspend"))

    assert {:ok, suspended} = Installations.suspend_installation(installation)
    assert suspended.suspended_at

    assert {:ok, unsuspended} = Installations.unsuspend_installation(suspended)
    assert is_nil(unsuspended.suspended_at)
  end
end
