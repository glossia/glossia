defmodule Glossia.AccountsTest do
  use Glossia.DataCase

  alias Glossia.Accounts

  describe "register_organization" do
    test "it registers the organization successfully" do
      # Given
      attrs = %{handle: "glossia"}

      # When
      assert {:ok, organization} = Accounts.register_organization(attrs)
    end

    test "errors when an organization with the same handle already exists" do
      # Given
      attrs = %{handle: "glossia"}

      # When
      assert {:ok, organization} = Accounts.register_organization(attrs)
      assert {:error, :account, account_changeset} = Accounts.register_organization(attrs)

      # Then
      errors = errors_on(account_changeset)
      assert %{handle: ["has already been taken"]} = errors
    end
  end
end
