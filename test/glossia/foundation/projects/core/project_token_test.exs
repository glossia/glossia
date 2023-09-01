defmodule Glossia.Foundation.Projects.Core.ProjectTokenTest do
  use Glossia.DataCase

  import Glossia.ProjectsFixtures
  import Glossia.Foundation.Projects.Core.ProjectToken

  describe "generate_token" do
    test "generates the token successfully" do
      # Given
      {:ok, project} = project_fixture()

      # When
      {:ok, token, _claims} = project.id |> generate_token_for_project_with_id()

      # Then
      assert token != ""
    end
  end

  describe "get_project_id_from_token" do
    test "it returns the build_id from a generated token" do
      # Given
      {:ok, project} = project_fixture()

      # When
      {:ok, token, _claims} = project.id |> generate_token_for_project_with_id()
      {:ok, project_id} = token |> get_project_id_from_token()

      # Then
      assert project_id == project.id
    end
  end
end
