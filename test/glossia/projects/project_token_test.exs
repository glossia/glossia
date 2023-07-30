defmodule Glossia.Events.ProjectTokenTest do
  use Glossia.DataCase

  import Glossia.ProjectsFixtures
  import Glossia.Projects.ProjectToken

  describe "generate_token" do
    test "generates the token successfully" do
      # Given
      {:ok, project} = project_fixture()

      # When
      {:ok, token, _claims} = project |> generate_token()

      # Then
      assert token != ""
    end
  end

  describe "get_project_id_from_token" do
    test "it returns the build_id from a generated token" do
      # Given
      {:ok, project} = project_fixture()

      # When
      {:ok, token, _claims} = project |> generate_token()
      {:ok, project_id} = token |> get_project_id_from_token()

      # Then
      assert project_id == project.id
    end
  end
end
