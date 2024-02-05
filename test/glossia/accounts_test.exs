defmodule Glossia.AccountsTest do
  use Glossia.DataCase

  alias Glossia.Accounts, as: Accounts
  alias Glossia.Accounts.Account

  describe "register_organization" do
    test "it registers the organization successfully" do
      # Given
      attrs = %{handle: Glossia.AccountsFixtures.unique_handle()}

      # When
      assert {:ok, _} = Accounts.register_organization(attrs)
    end

    test "errors when an organization with the same handle already exists" do
      # Given
      attrs = %{handle: Glossia.AccountsFixtures.unique_handle()}

      # When
      assert {:ok, _} = Accounts.register_organization(attrs)
      assert {:error, :account, account_changeset} = Accounts.register_organization(attrs)

      # Then
      errors = errors_on(account_changeset)
      assert %{handle: ["has already been taken"]} = errors
    end
  end

  # describe "add_user_to_organization" do
  #   test "makes a user admin of the organization" do
  #     # Given
  #     organization = Glossia.AccountsFixtures.organization_fixture()
  #     user = Glossia.AccountsFixtures.user_fixture()

  #     # When
  #     assert {:ok, _} =
  #              Glossia.Accounts.add_user_to_organization(
  #                user.id,
  #                organization.id,
  #                :admin
  #              )
  #   end

  #   test "makes a user member of the organization" do
  #     # Given
  #     organization = Glossia.AccountsFixtures.organization_fixture()
  #     user = Glossia.AccountsFixtures.user_fixture()

  #     # When
  #     assert {:ok, _} =
  #              Glossia.Accounts.add_user_to_organization(
  #                user.id,
  #                organization.id,
  #                :user
  #              )
  #   end
  # end

  describe "find_account_by_handle" do
    test "it finds the account by handle" do
      # Given
      user = Glossia.AccountsFixtures.user_fixture()
      handle = user.account.handle

      # When
      assert %Account{handle: ^handle} =
               Glossia.Accounts.find_account_by_handle(handle)
    end

    test "it returns nil when the account doesn't exist" do
      # When/Then
      assert Glossia.Accounts.find_account_by_handle("unknown") == nil
    end
  end

  describe "get_last_visited_project_for_user" do
    test "it returns the last visited project for the user" do
      # Given
      user = Glossia.AccountsFixtures.user_fixture()
      project = Glossia.ProjectsFixtures.project_fixture()
      :ok = Accounts.update_last_visited_project_for_user(user, project)

      # When
      got_project = Accounts.get_last_visited_project_or_first_for_user(user)

      # Then
      assert got_project.id == project.id
    end

    test "it returns nil if there are no projects" do
      # Given
      user = Glossia.AccountsFixtures.user_fixture()

      # When
      got_project = Accounts.get_last_visited_project_or_first_for_user(user)

      # Then
      assert got_project == nil
    end
  end
end
