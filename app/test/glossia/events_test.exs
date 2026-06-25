defmodule Glossia.EventsTest do
  use ExUnit.Case, async: true
  use Mimic

  alias Glossia.Events

  test "emits events through the configured handler" do
    account = %{id: 123}
    user = %{id: 456}

    Mimic.stub(Glossia.Extensions, :event_handler, fn -> Glossia.TestEventHandler end)

    expect(Glossia.TestEventHandler, :handle_event, fn event ->
      assert event.name == "project.created"
      assert event.account == account
      assert event.user == user
      assert event.opts[:resource_type] == "project"
      assert event.opts[:resource_id] == "abc123"

      :ok
    end)

    assert :ok =
             Events.emit("project.created", account, user,
               resource_type: "project",
               resource_id: "abc123",
               summary: "Project created"
             )
  end
end
