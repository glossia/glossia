defmodule Glossia.Admin.MCP.SetSuperAdminToolTest do
  use Glossia.DataCase, async: true

  alias Glossia.Accounts
  alias Glossia.Admin.MCP.SetSuperAdminTool
  alias Glossia.TestHelpers
  alias Hermes.Server.Frame

  setup do
    admin = TestHelpers.create_user("set-sa-admin@test.com", "set-sa-admin")
    target = TestHelpers.create_user("set-sa-target@test.com", "set-sa-target")

    {:ok, _admin} = Accounts.set_super_admin(admin.id)
    %{admin: admin, target: target}
  end

  defp frame_for(user) do
    Frame.new(%{current_user: user, scopes: nil})
  end

  test "successful response does not include the super_admin field", %{
    admin: admin,
    target: target
  } do
    assert {:reply, response, _frame} =
             SetSuperAdminTool.execute(
               %{"email" => target.email, "super_admin" => true},
               frame_for(admin)
             )

    [content] = response.content
    result = JSON.decode!(content["text"])

    assert result == %{"email" => target.email}
    refute Map.has_key?(result, "super_admin")
  end
end
