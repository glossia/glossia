defmodule Glossia.VersionControl.GitHub.AppTokenTest do
  use Glossia.DataCase

  alias Glossia.VersionControl.GitHub.AppToken

  test "generates a token" do
    # Given
    {:ok, token, _} = AppToken.generate_and_sign(%{foo: "bar"})

    # When
    assert {:ok, %{"foo" => "bar"}} = AppToken.verify_and_validate(token)
  end
end
