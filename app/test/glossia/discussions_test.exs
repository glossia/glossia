defmodule Glossia.DiscussionsTest do
  use Glossia.DataCase, async: true

  alias Glossia.Discussions
  alias Glossia.TestHelpers

  describe "create_discussion/3" do
    test "assigns incrementing numbers per account" do
      %{account: account} = user = TestHelpers.create_user("tickets@test.com", "tickets-user")

      assert {:ok, discussion_one} =
               Discussions.create_discussion(account, user, %{
                 title: "First discussion",
                 body: "First body"
               })

      assert {:ok, discussion_two} =
               Discussions.create_discussion(account, user, %{
                 title: "Second discussion",
                 body: "Second body"
               })

      assert discussion_one.number == 1
      assert discussion_two.number == 2
    end

    test "persists suggestion kind and metadata" do
      %{account: account} =
        user = TestHelpers.create_user("change-request@test.com", "cr-user")

      attrs = %{
        title: "Voice suggestion: tone update",
        body: "Please apply this proposal.",
        kind: "voice_suggestion",
        metadata: %{
          "resource" => "voice",
          "change_note" => "Adjust tone",
          "payload" => %{"tone" => "casual", "formality" => "neutral"}
        }
      }

      assert {:ok, discussion} = Discussions.create_discussion(account, user, attrs)
      assert discussion.kind == "voice_suggestion"
      assert discussion.metadata["resource"] == "voice"
      assert discussion.metadata["change_note"] == "Adjust tone"
    end

    test "rejects invalid discussion kind" do
      %{account: account} = user = TestHelpers.create_user("invalid-kind@test.com", "bad-kind")

      assert {:error, changeset} =
               Discussions.create_discussion(account, user, %{
                 title: "Invalid",
                 body: "Invalid kind",
                 kind: "unsupported_kind"
               })

      assert "is invalid" in errors_on(changeset).kind
    end
  end

  describe "get_discussion/1" do
    test "returns nil for invalid UUID values" do
      assert Discussions.get_discussion("not-a-uuid") == nil
    end
  end
end
