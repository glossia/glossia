defmodule Glossia.DiscussionsTest do
  use Glossia.DataCase, async: true

  alias Glossia.Discussions
  alias Glossia.TestHelpers

  test "create_discussion/4 assigns the next number and emits an event" do
    user = TestHelpers.create_user("discussion-create@test.com", "discussion-create")

    attrs = %{"title" => "First discussion", "body" => "Body"}

    assert {:ok, discussion} =
             TestHelpers.expect_event(
               "discussion.created",
               fn ->
                 Discussions.create_discussion(user.account, user, attrs, via: :dashboard)
               end,
               %{
                 :account_id => user.account.id,
                 :user_id => user.id,
                 {:opt, :via} => :dashboard,
                 {:opt, :resource_type} => "discussion"
               }
             )

    assert discussion.number == 1
    assert discussion.title == "First discussion"
  end

  test "create_discussion/4 emits voice suggestion events for suggestion discussions" do
    user = TestHelpers.create_user("voice-suggestion@test.com", "voice-suggestion")

    attrs = %{
      "title" => "Suggest voice",
      "body" => "Please update it",
      "kind" => "voice_suggestion",
      "metadata" => %{"payload" => %{"tone" => "neutral"}}
    }

    assert {:ok, _discussion} =
             TestHelpers.expect_event(
               "voice.suggested",
               fn ->
                 Discussions.create_discussion(user.account, user, attrs, via: :dashboard)
               end,
               %{{:opt, :via} => :dashboard}
             )
  end

  test "add_comment/4 creates a comment and emits an event" do
    user = TestHelpers.create_user("discussion-comment@test.com", "discussion-comment")

    {:ok, discussion} =
      Discussions.create_discussion(user.account, user, %{"title" => "Topic", "body" => "Body"})

    assert {:ok, comment} =
             TestHelpers.expect_event(
               "discussion.commented",
               fn ->
                 Discussions.add_comment(discussion, user, %{"body" => "First comment"},
                   via: :api
                 )
               end,
               %{{:opt, :via} => :api, :account_id => user.account.id, :user_id => user.id}
             )

    assert comment.body == "First comment"
  end

  test "close_discussion/3 closes the discussion and emits an event" do
    user = TestHelpers.create_user("discussion-close@test.com", "discussion-close")

    {:ok, discussion} =
      Discussions.create_discussion(user.account, user, %{"title" => "Topic", "body" => "Body"})

    assert {:ok, closed} =
             TestHelpers.expect_event(
               "discussion.closed",
               fn -> Discussions.close_discussion(discussion, user, via: :dashboard) end,
               %{{:opt, :via} => :dashboard, :account_id => user.account.id, :user_id => user.id}
             )

    assert closed.status == "closed"
    assert closed.closed_by_id == user.id
  end

  test "reopen_discussion/3 reopens the discussion and emits an event" do
    user = TestHelpers.create_user("discussion-reopen@test.com", "discussion-reopen")

    {:ok, discussion} =
      Discussions.create_discussion(user.account, user, %{"title" => "Topic", "body" => "Body"})

    {:ok, closed} = Discussions.close_discussion(discussion, user)

    assert {:ok, reopened} =
             TestHelpers.expect_event(
               "discussion.reopened",
               fn -> Discussions.reopen_discussion(closed, user, via: :mcp) end,
               %{{:opt, :via} => :mcp, :account_id => user.account.id, :user_id => user.id}
             )

    assert reopened.status == "open"
    assert is_nil(reopened.closed_at)
    assert is_nil(reopened.closed_by_id)
  end

  test "mark_suggestion_applied/5 closes, comments, and emits applied event" do
    user = TestHelpers.create_user("discussion-apply@test.com", "discussion-apply")

    {:ok, discussion} =
      Discussions.create_discussion(user.account, user, %{
        "title" => "Suggest glossary",
        "body" => "Please apply",
        "kind" => "glossary_suggestion",
        "metadata" => %{"change_note" => "change"}
      })

    Mimic.stub(Glossia.Extensions, :event_handler, fn -> Glossia.TestEventHandler end)

    test_pid = self()

    Mimic.expect(Glossia.TestEventHandler, :handle_event, 3, fn event ->
      send(test_pid, {:glossia_event, event})
      :ok
    end)

    assert :ok =
             Discussions.mark_suggestion_applied(discussion, user, :glossary, 3, via: :dashboard)

    assert_receive {:glossia_event, closed_event}
    assert closed_event.name == "discussion.closed"

    assert_receive {:glossia_event, commented_event}
    assert commented_event.name == "discussion.commented"

    assert_receive {:glossia_event, applied_event}
    assert applied_event.name == "glossary.suggestion.applied"
    assert applied_event.opts[:via] == :dashboard

    updated = Discussions.get_discussion!(discussion.id)
    assert updated.status == "closed"
    assert length(updated.comments) == 1
    assert Enum.at(updated.comments, 0).body =~ "version #3"
  end
end
