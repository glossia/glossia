defmodule Glossia.AccountsTest do
  use Glossia.DataCase

  alias Glossia.Accounts
  alias Glossia.Accounts.Account

  describe "register_organization" do
    test "it registers the organization successfully" do
      # Given
      attrs = %{handle: "glossia"}

      # When
      assert {:ok, _} = Accounts.register_organization(attrs)
    end

    test "errors when an organization with the same handle already exists" do
      # Given
      attrs = %{handle: "glossia"}

      # When
      assert {:ok, _} = Accounts.register_organization(attrs)
      assert {:error, :account, account_changeset} = Accounts.register_organization(attrs)

      # Then
      errors = errors_on(account_changeset)
      assert %{handle: ["has already been taken"]} = errors
    end
  end

  describe "add_user_to_organization" do
    test "makes a user admin of the organization" do
      # Given
      organization = Glossia.AccountsFixtures.organization_fixture()
      user = Glossia.AccountsFixtures.user_fixture()

      # When
      assert {:ok, _} =
               Glossia.Accounts.add_user_to_organization(user.id, organization.id, :admin)
    end

    test "makes a user member of the organization" do
      # Given
      organization = Glossia.AccountsFixtures.organization_fixture()
      user = Glossia.AccountsFixtures.user_fixture()

      # When
      assert {:ok, _} =
               Glossia.Accounts.add_user_to_organization(user.id, organization.id, :user)
    end
  end

  describe "find_account_by_handle" do
    test "it finds the account by handle" do
      # Given
      user = Glossia.AccountsFixtures.user_fixture()
      handle = user.account.handle

      # When
      assert %Account{handle: ^handle} = Glossia.Accounts.find_account_by_handle(handle)
    end

    test "it returns nil when the account doesn't exist" do
      # When/Then
      assert Glossia.Accounts.find_account_by_handle("unknown") == nil
    end
  end
end
