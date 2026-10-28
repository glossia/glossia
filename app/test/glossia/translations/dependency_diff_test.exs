defmodule Glossia.Translations.DependencyDiffTest do
  use ExUnit.Case, async: true

  alias Glossia.Translations.DependencyDiff

  test "preserves full ancestry when labels repeat in different branches" do
    previous =
      node("root", %{}, [
        node("project", %{}, [node("voice", %{"tone_hash" => "a"})]),
        node("locale", %{}, [node("voice", %{"tone_hash" => "b"})])
      ])

    current =
      put_in(
        previous,
        ["children", Access.at(1), "children", Access.at(0), "metadata", "tone_hash"],
        "c"
      )

    diff = DependencyDiff.diff(previous, current)

    assert [%{"label" => "locale", "children" => [%{"label" => "voice", "fields" => [field]}]}] =
             diff["children"]

    assert field["before"] == "b"
    assert field["after"] == "c"
    assert DependencyDiff.field_count(diff) == 1
  end

  test "added, removed, null and false fields remain distinguishable" do
    diff =
      DependencyDiff.diff(
        node("config", %{"nullable" => nil, "removed" => false, "flag" => false}),
        node("config", %{"added" => nil, "nullable" => false, "flag" => true})
      )

    fields = Map.new(diff["fields"], &{&1["field"], &1})
    assert fields["added"]["change"] == "added"
    refute fields["added"]["before_present"]
    assert fields["added"]["after_present"]
    assert fields["removed"]["change"] == "removed"
    assert fields["removed"]["before"] == false
    assert fields["nullable"]["change"] == "changed"
    assert fields["nullable"]["before"] == nil
    assert fields["nullable"]["after"] == false
  end

  test "diagnostic changes alone never invent an invalidation" do
    previous = Map.put(node("context", %{"content_hash" => "same"}), "details", %{})
    current = Map.put(previous, "details", %{"content_hash" => %{"tone_hash" => "new detail"}})
    assert DependencyDiff.diff(previous, current) == nil
  end

  test "uses field-level evidence when both snapshots have it" do
    before =
      Map.put(node("voice", %{"content_hash" => "a"}), "details", %{
        "content_hash" => %{"tone_hash" => "old", "guidelines_hash" => "same"}
      })

    current =
      before
      |> put_in(["metadata", "content_hash"], "b")
      |> put_in(["details", "content_hash", "tone_hash"], "new")

    diff = DependencyDiff.diff(before, current)
    assert diff["fields"] == []

    assert [
             %{
               "label" => "content_hash",
               "fields" => [
                 %{
                   "field" => "tone_hash",
                   "before" => "old",
                   "after" => "new",
                   "fingerprint" => true
                 }
               ]
             }
           ] = diff["children"]

    assert DependencyDiff.field_count(diff) == 1
  end

  test "does not fabricate old per-field values for a coarse baseline" do
    previous = node("voice", %{"content_hash" => "a"})

    current =
      Map.put(node("voice", %{"content_hash" => "b"}), "details", %{
        "content_hash" => %{"tone_hash" => "new"}
      })

    diff = DependencyDiff.diff(previous, current)
    assert diff["aggregate_only"]
    assert diff["children"] == []
    assert [%{"field" => "content_hash", "before" => "a", "after" => "b"}] = diff["fields"]
  end

  test "retains removed dependency branches" do
    diff =
      DependencyDiff.diff(
        node("root", %{}, [node("quality", %{"minimum_score" => 7})]),
        node("root", %{})
      )

    assert [%{"label" => "quality", "change" => "removed", "fields" => [field]}] =
             diff["children"]

    assert field["before"] == 7
    refute field["after_present"]
  end

  defp node(label, metadata, children \\ []),
    do: %{"kind" => "test", "label" => label, "metadata" => metadata, "children" => children}
end
