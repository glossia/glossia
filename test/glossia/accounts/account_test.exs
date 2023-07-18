defmodule Glossia.Accounts.AccountTest do
  use Glossia.DataCase

  alias Glossia.Accounts.Account

  describe "create_acccount_changeset" do
    test "validates the presence of handle" do
      # Given
      attrs = %{}

      # When
      changeset = Account.create_acccount_changeset(attrs)

      # Then
      errors = errors_on(changeset)
      assert %{handle: ["can't be blank"]} = errors
    end

    test "validates the uniqueness of handle" do
      # Given
      attrs = %{handle: "glossia"}
      Account.create_acccount_changeset(attrs) |> Repo.insert!()

      # When
      {:error, changeset} = Account.create_acccount_changeset(attrs) |> Repo.insert()

      # Then
      errors = errors_on(changeset)
      assert %{handle: ["has already been taken"]} = errors
    end
  end
end
