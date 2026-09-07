defmodule Glossia.AuthzTest do
  use Glossia.DataCase, async: true

  alias Glossia.Accounts
  alias Glossia.Authz
  alias Glossia.TestHelpers

  defmodule TestPolicyExtension do
    def required_scope(:custom_read), do: "custom:read"
    def required_scope(_action), do: nil

    def available_scopes, do: ["custom:read"]

    def authorize(:custom_read, :allowed, _object, _opts), do: :ok
    def authorize(:custom_read, _subject, _object, _opts), do: {:error, :unauthorized}
    def authorize(_action, _subject, _object, _opts), do: :unknown_action
  end

  describe "required_scope/1" do
    test "returns the built-in policy scope" do
      Mimic.stub(Glossia.Extensions, :policy_extension, fn -> nil end)

      assert Authz.required_scope(:voice_read) == "voice:read"
    end

    test "returns the extension scope for custom actions" do
      Mimic.stub(Glossia.Extensions, :policy_extension, fn -> TestPolicyExtension end)

      assert Authz.required_scope(:custom_read) == "custom:read"
    end
  end

  describe "required_scope!/1" do
    test "raises for unknown actions" do
      Mimic.stub(Glossia.Extensions, :policy_extension, fn -> nil end)

      assert_raise ArgumentError, ~r/unknown policy action/, fn ->
        Authz.required_scope!(:unknown_action)
      end
    end
  end

  describe "available_scopes/0" do
    test "merges built-in and extension scopes" do
      Mimic.stub(Glossia.Extensions, :policy_extension, fn -> TestPolicyExtension end)

      scopes = Authz.available_scopes()

      assert "voice:read" in scopes
      assert "custom:read" in scopes
    end
  end

  describe "authorize/4" do
    test "falls back to the built-in policy for built-in actions" do
      Mimic.stub(Glossia.Extensions, :policy_extension, fn -> TestPolicyExtension end)

      user = TestHelpers.create_user("authz@test.com", "authz")

      assert :ok = Authz.authorize(:user_write, user, user)
    end

    test "uses the extension for custom actions" do
      Mimic.stub(Glossia.Extensions, :policy_extension, fn -> TestPolicyExtension end)

      assert :ok = Authz.authorize(:custom_read, :allowed, nil, scopes: ["custom:read"])

      assert {:error, :unauthorized} =
               Authz.authorize(:custom_read, :blocked, nil, scopes: ["custom:read"])
    end
  end

  describe "authorize_scope/2" do
    test "returns insufficient scope for missing built-in scopes" do
      Mimic.stub(Glossia.Extensions, :policy_extension, fn -> nil end)

      assert {:error, :insufficient_scope, "voice:read"} =
               Authz.authorize_scope(:voice_read, ["project:read"])
    end

    test "supports custom extension scopes" do
      Mimic.stub(Glossia.Extensions, :policy_extension, fn -> TestPolicyExtension end)

      assert :ok = Authz.authorize_scope(:custom_read, ["custom:read"])
    end
  end

  describe "admin / ops super admin checks via the policy" do
    test "admin_read and ops_read both allow super admins and deny non-admins" do
      Mimic.stub(Glossia.Extensions, :policy_extension, fn -> nil end)

      admin = TestHelpers.create_user("authz-admin@test.com", "authz-admin")
      member = TestHelpers.create_user("authz-member@test.com", "authz-member")

      assert {:ok, _admin} = Accounts.set_super_admin(admin.id)

      assert Authz.authorize?(:admin_read, admin, nil)
      assert Authz.authorize?(:ops_read, admin, nil)
      refute Authz.authorize?(:admin_read, member, nil)
      refute Authz.authorize?(:ops_read, member, nil)
      refute Authz.authorize?(:admin_read, nil, nil)
      refute Authz.authorize?(:ops_read, nil, nil)
    end
  end
end
