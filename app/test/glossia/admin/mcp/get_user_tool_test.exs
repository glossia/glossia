defmodule Glossia.Admin.MCP.GetUserToolTest do
  use Glossia.DataCase, async: true

  alias Glossia.Accounts
  alias Glossia.Admin.MCP.GetUserTool
  alias Glossia.TestHelpers
  alias Hermes.Server.Frame

  setup do
    admin = TestHelpers.create_user("get-user-admin@test.com", "get-user-admin")
    target = TestHelpers.create_user("get-user-target@test.com", "get-user-target")

    {:ok, _admin} = Accounts.set_super_admin(admin.id)
    %{admin: admin, target: target}
  end

  defp frame_for(user) do
    Frame.new(%{current_user: user, scopes: nil})
  end

  describe "execute/2 super_admin field leakage" do
    test "the response does not include the target's super_admin status", %{
      admin: admin,
      target: target
    } do
      assert {:reply, response, _frame} =
               GetUserTool.execute(%{"email" => target.email}, frame_for(admin))

      [content] = response.content
      result = JSON.decode!(content["text"])

      refute Map.has_key?(result, "super_admin"),
             "expected no super_admin field in the response, got: #{inspect(result)}"
    end

    test "the response does not include the target's super_admin status when looking up by handle",
         %{admin: admin, target: target} do
      assert {:reply, response, _frame} =
               GetUserTool.execute(%{"handle" => target.account.handle}, frame_for(admin))

      [content] = response.content
      result = JSON.decode!(content["text"])

      refute Map.has_key?(result, "super_admin")
    end

    test "the admin asking for themselves also has no super_admin in the response", %{
      admin: admin
    } do
      assert {:reply, response, _frame} =
               GetUserTool.execute(%{"email" => admin.email}, frame_for(admin))

      [content] = response.content
      result = JSON.decode!(content["text"])

      refute Map.has_key?(result, "super_admin")
    end
  end
end
