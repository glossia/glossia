defmodule Glossia.AccountsTest do
  use Glossia.DataCase

  alias Glossia.Accounts

  describe "register_organization" do
    test "it registers the organization successfully" do
      # Given
      attrs = %{account: %{handle: "glossia"}}

      # When
      # {:ok, organization} = Accounts.register_organization(attrs)

      # Then
      # errors = errors_on(changeset)
      # assert %{account: ["can't be blank"]} = errors
    end
  end
end
