defmodule Glossia.Builds.TokenTest do
  use Glossia.DataCase

  import Glossia.BuildsFixtures
  alias Glossia.Builds.Token

  describe "generate_token" do
    test "generates the token successfully" do
      # Given
      {:ok, build} = build_fixture()

      # When
      {:ok, token, _claims} = build |> Token.generate_token()

      # Then
      assert token != ""
    end
  end

  describe "get_build_id_from_token" do
    test "it returns the build_id from a generated token" do
      # Given
      {:ok, build} = build_fixture()

      # When
      {:ok, token, _claims} = build |> Token.generate_token()
      {:ok, build_id} = token |> Token.get_build_id_from_token()

      # Then
      assert build_id == build.id
    end
  end
end
