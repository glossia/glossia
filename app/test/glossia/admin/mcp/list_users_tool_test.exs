defmodule Glossia.Admin.MCP.ListUsersToolTest do
  use Glossia.DataCase, async: true

  alias Glossia.Accounts
  alias Glossia.Admin.MCP.ListUsersTool
  alias Glossia.TestHelpers
  alias Hermes.Server.Frame

  setup do
    admin = TestHelpers.create_user("list-users-admin@test.com", "list-users-admin")
    {:ok, _admin} = Accounts.set_super_admin(admin.id)
    %{admin: admin}
  end

  defp frame_for(user) do
    Frame.new(%{current_user: user, scopes: nil})
  end

  test "each user entry in the response omits the super_admin field", %{admin: admin} do
    # Some non-admin users to be returned in the list.
    _member = TestHelpers.create_user("list-users-member-a@test.com", "list-users-member-a")
    _member2 = TestHelpers.create_user("list-users-member-b@test.com", "list-users-member-b")

    assert {:reply, response, _frame} =
             ListUsersTool.execute(%{}, frame_for(admin))

    [content] = response.content
    result = JSON.decode!(content["text"])

    assert is_list(result)
    assert length(result) >= 3

    Enum.each(result, fn entry ->
      refute Map.has_key?(entry, "super_admin"),
             "expected no super_admin field in user entry, got: #{inspect(entry)}"
    end)
  end
end
