defmodule Glossia.Translations.ExtractionPlanTest do
  use ExUnit.Case, async: true

  alias Glossia.Translations.ExtractionPlan

  test "resolves an exact repeated excerpt with Unicode anchors and restores it losslessly" do
    source = "👋 Hello {name}. 👋 Hello {name}."

    locators = [
      %{
        "excerpt" => "{name}",
        "occurrence" => 1,
        "before" => "👋 Hello ",
        "after" => ".",
        "kind" => "placeholders"
      },
      %{
        "excerpt" => "{name}",
        "occurrence" => 2,
        "kind" => "placeholders"
      }
    ]

    assert {:ok, plan} = ExtractionPlan.from_locators(source, locators)
    refute plan.text =~ "{name}"
    assert length(plan.regions) == 2
    assert {:ok, ^source} = ExtractionPlan.restore(plan.text, plan)
  end

  test "rejects a locator that cannot be resolved exactly" do
    assert {:error, message} =
             ExtractionPlan.from_locators("Hello {name}", [
               %{excerpt: "{name}", occurrence: 2, kind: "placeholders"}
             ])

    assert message =~ "occurrence 2 was not found"
  end

  test "rejects overlapping source locators" do
    assert {:error, message} =
             ExtractionPlan.from_locators("abcdef", [
               %{excerpt: "abc", occurrence: 1, kind: "syntax"},
               %{excerpt: "bc", occurrence: 1, kind: "syntax"}
             ])

    assert message =~ "overlap"
  end

  test "rejects deterministic ranges that do not match the original source" do
    assert {:error, message} =
             ExtractionPlan.build("Hello", [
               %{start: 0, length: 5, value: "Other", kind: "syntax"}
             ])

    assert message =~ "does not match the original source"
  end

  test "uses scope to keep markers unique across independently planned regions" do
    source = "Hello {name}"
    ranges = [%{start: 6, length: 6, value: "{name}", kind: "placeholders"}]

    assert {:ok, left} = ExtractionPlan.build(source, ranges, scope: "frontmatter")
    assert {:ok, right} = ExtractionPlan.build(source, ranges, scope: "body")
    assert left.text != right.text
  end
end
