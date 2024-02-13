defmodule Glossia.Builds.BuildTest do
  use Glossia.DataCase

  alias Glossia.Builds.Build

  describe "changeset" do
    test "validates the presence of version" do
      # Given
      attrs = %{}

      # When
      changeset = Build.changeset(%Build{}, attrs)

      # Then
      errors = errors_on(changeset)
      assert %{version: ["can't be blank"]} = errors
    end

    test "validates the presence of project_id" do
      # Given
      attrs = %{
        version: "1234567890"
      }

      # When
      changeset = Build.changeset(%Build{}, attrs)

      # Then
      errors = errors_on(changeset)
      assert %{project_id: ["can't be blank"]} = errors
    end
  end
end
