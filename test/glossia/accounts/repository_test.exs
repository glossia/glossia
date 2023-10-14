defmodule Glossia.Accounts.RepositoryTest do
  @moduledoc false

  alias Glossia.Accounts.Repository
  alias Glossia.AccountsFixtures
  use Glossia.DataCase

  describe "get_user_account" do
    test "returns the user's account" do
      # Given
      user = AccountsFixtures.user_fixture()

      # When
      got = Repository.get_user_account(user)

      # Then
      assert got != nil
    end
  end

  describe "get_user_and_organization_accounts" do
    test "returns the user and organization accounts" do
      # Given
      user = AccountsFixtures.user_fixture() |> Repo.preload(:account)
      organization = AccountsFixtures.organization_fixture() |> Repo.preload(:account)
      Repository.add_user_to_organization(user, organization)

      # When
      results = Repository.get_user_and_organization_accounts(user)

      # Then
      assert Enum.any?(results, fn account -> account.id == user.account.id end) == true
      assert Enum.any?(results, fn account -> account.id == organization.account.id end) == true
    end
  end

  describe "add_user_to_organization" do
    test "should add the user to the organization if it doesn't exist" do
      # Given
      user = AccountsFixtures.user_fixture()
      organization = AccountsFixtures.organization_fixture()

      # When
      got = Repository.add_user_to_organization(user, organization)

      # Then
      assert got.user_id == user.id
      assert got.organization_id == organization.id
    end

    test "it's an idempotent operation" do
      # Given
      user = AccountsFixtures.user_fixture()
      organization = AccountsFixtures.organization_fixture()

      # When
      _ = Repository.add_user_to_organization(user, organization)
      got = Repository.add_user_to_organization(user, organization)

      # Then
      assert got.user_id == user.id
      assert got.organization_id == organization.id
    end
  end

  describe "get_user_organizations" do
    test "returns the organizations that a user is member of" do
      # Given
      user = AccountsFixtures.user_fixture()
      organization = AccountsFixtures.organization_fixture()

      # When
      Repository.add_user_to_organization(user, organization)
      [got_organization] = Repository.get_user_organizations(user)

      # Then
      assert got_organization.id == organization.id
    end

    test "returns an empty list if the user is not member of any organization" do
      # Given
      user = AccountsFixtures.user_fixture()

      # When
      assert [] == Repository.get_user_organizations(user)
    end
  end
end
