defmodule Glossia.Foundation.Accounts.Core.Models.OrganizationTest do
  use Glossia.DataCase

  alias Glossia.Foundation.Accounts.Core.Models.Organization

  describe "create_organization_changeset" do
    test "validates the presence of account_id" do
      # Given
      attrs = %{}

      # When
      changeset = Organization.create_organization_changeset(attrs)

      # Then
      errors = errors_on(changeset)
      assert %{account_id: ["can't be blank"]} = errors
    end
  end
end
