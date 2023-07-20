defmodule Glossia.Accounts.AccountTest do
  use Glossia.DataCase

  alias Glossia.Accounts.Account

  describe "changeset" do
    test "validates the presence of handle" do
      # Given
      attrs = %{}

      # When
      changeset = Account.changeset(%Account{}, attrs)

      # Then
      errors = errors_on(changeset)
      assert %{handle: ["can't be blank"]} = errors
    end

    test "validates the uniqueness of handle" do
      # Given
      attrs = %{handle: "glossia"}
      %Account{} |> Account.changeset(attrs) |> Repo.insert!()

      # When
      {:error, changeset} = %Account{} |> Account.changeset(attrs) |> Repo.insert()

      # Then
      errors = errors_on(changeset)
      assert %{handle: ["has already been taken"]} = errors
    end

    test "validates the exclussion of the handle" do
      # Given
      attrs = %{handle: Account.reserved_handles() |> Enum.random()}

      # When
      {:error, changeset} = %Account{} |> Account.changeset(attrs) |> Repo.insert()

      # Then
      errors = errors_on(changeset)
      assert %{handle: ["is reserved"]} = errors
    end

    test "validates the handles are alphanumeric" do
      # Given
      attrs = %{handle: "invalid.handle"}

      # When
      {:error, changeset} = %Account{} |> Account.changeset(attrs) |> Repo.insert()

      # Then
      errors = errors_on(changeset)
      assert %{handle: ["must be alphanumeric"]} = errors
    end
  end
end
