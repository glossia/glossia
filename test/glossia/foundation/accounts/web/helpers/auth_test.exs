defmodule GlossiaWeb.Helpers.AuthTest do
  alias Glossia.Foundation.AccountsFixtures
  use Glossia.Web.ConnCase
  import GlossiaWeb.Helpers.Auth

  describe "user_authenticated?" do
    test "returns true when there's a user in the connection", %{conn: conn} do
      # Given
      user = AccountsFixtures.user_fixture()
      conn = assign(conn, :authenticated_user, user)

      # When
      result = user_authenticated?(conn)

      # Then
      assert result == true
    end

    test "returns false when there's no user in the connection", %{conn: conn} do
      # When
      result = user_authenticated?(conn)

      # Then
      assert result == false
    end
  end

  describe "authenticated_user" do
    test "returns the authenticated user if there's an authenticated in the connection", %{
      conn: conn
    } do
      # Given
      user = AccountsFixtures.user_fixture()
      conn = assign(conn, :authenticated_user, user)

      # When
      got = authenticated_user(conn)

      # Then
      assert got == user
    end

    test "returns nil if there's no in the connection", %{conn: conn} do
      # When
      got = authenticated_user(conn)

      # Then
      assert got == nil
    end
  end
end
