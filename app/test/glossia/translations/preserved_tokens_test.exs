defmodule Glossia.Translations.PreservedTokensTest do
  use ExUnit.Case, async: true

  alias Glossia.Translations.PreservedTokens

  test "masks and restores atomic values without parsing the Markdown document" do
    source = """
    Read [the guide](https://example.com/guide) and keep `{locale}`.

    ~~~elixir
    IO.puts("https://inside.example")
    ~~~
    """

    protection = PreservedTokens.protect(source, PreservedTokens.resolve([]))

    assert protection.text =~ "https://example.com/guide"
    refute protection.text =~ "IO.puts"
    refute protection.text =~ "{locale}"

    translated = String.replace(protection.text, "Read", "Lee")
    assert {:ok, restored} = PreservedTokens.restore(translated, protection)
    assert restored =~ "[the guide](https://example.com/guide)"
    assert restored =~ "`{locale}`"
    assert restored =~ "IO.puts(\"https://inside.example\")"
  end

  test "reports a missing or duplicated marker" do
    protection = PreservedTokens.protect("Hello {name}.", ["placeholders"])
    [{marker, _value}] = protection.replacements

    assert {:error, message} =
             protection.text
             |> String.replace(marker, "")
             |> PreservedTokens.restore(protection)

    assert message =~ "occurred 0 times"

    assert {:error, message} =
             PreservedTokens.restore(protection.text <> marker, protection)

    assert message =~ "occurred 2 times"
  end

  test "keeps web addresses visible to the model" do
    protection =
      PreservedTokens.protect(
        "Follow [Anthropic](https://anthropic.com) closely.",
        ["urls"]
      )

    assert protection.replacements == []
    assert protection.text == "Follow [Anthropic](https://anthropic.com) closely."

    assert {:ok, "Sigue [Anthropic](https://anthropic.com) de cerca."} =
             protection.text
             |> String.replace("Follow", "Sigue")
             |> String.replace(" closely.", " de cerca.")
             |> PreservedTokens.restore(protection)
  end

  test "masks a web address whole when it carries another protected value" do
    protection =
      PreservedTokens.protect("Read [the guide](https://glossia.ai/{locale}/docs).", [
        "urls",
        "placeholders"
      ])

    [{marker, "https://glossia.ai/{locale}/docs"}] = protection.replacements

    # The model must never see a half-real address: it repairs those.
    refute protection.text =~ "https://glossia.ai"
    assert protection.text == "Read [the guide](#{marker})."

    assert {:ok, "Lee [la guía](https://glossia.ai/{locale}/docs)."} =
             protection.text
             |> String.replace("Read", "Lee")
             |> String.replace("[the guide]", "[la guía]")
             |> PreservedTokens.restore(protection)
  end

  test "leaves a placeholder beside a plain web address visible and masks the placeholder" do
    protection =
      PreservedTokens.protect("Open https://glossia.ai for {count} items.", [
        "urls",
        "placeholders"
      ])

    assert protection.text =~ "https://glossia.ai"
    refute protection.text =~ "{count}"
  end

  test "ends a bare web address at the sentence, not at the next space" do
    # Japanese and Chinese put no space after the address, so a scan that only
    # stops at whitespace swallows the translated sentence that follows it.
    assert PreservedTokens.values("詳細は https://example.com/a。次をご覧ください", ["urls"]) ==
             ["https://example.com/a"]

    assert PreservedTokens.values("参照（https://example.com/a）", ["urls"]) ==
             ["https://example.com/a"]
  end

  test "treats trailing sentence punctuation as prose, not as part of the address" do
    for source <- [
          "See https://example.com/a.",
          "Voir https://example.com/a, puis",
          "Siehe https://example.com/a!",
          "**https://example.com/a**"
        ] do
      assert PreservedTokens.values(source, ["urls"]) == ["https://example.com/a"]
    end
  end

  test "reports values the output did not reproduce, counting occurrences" do
    excerpt = "Compare https://a.example with https://b.example and https://a.example."

    assert PreservedTokens.unpreserved_values(excerpt, excerpt, ["urls"]) == []

    assert PreservedTokens.unpreserved_values(
             excerpt,
             "Compara https://a.example con https://b.example.",
             ["urls"]
           ) == ["https://a.example"]

    assert PreservedTokens.unpreserved_values(
             excerpt,
             "Compara https://a.example/es con https://b.example.",
             ["urls"]
           ) == ["https://a.example", "https://a.example"]
  end

  test "finds repeated web addresses for output validation" do
    source =
      "Compare [one](https://anthropic.com) with [two](https://anthropic.com)."

    assert PreservedTokens.values(source, ["urls"]) == [
             "https://anthropic.com",
             "https://anthropic.com"
           ]
  end

  test "finds web addresses after the tenth occurrence" do
    source =
      0..11
      |> Enum.map_join(" ", fn index -> "https://example.com/#{index}" end)

    assert length(PreservedTokens.values(source, ["urls"])) == 12
  end

  test "none disables masking" do
    assert %{text: "https://example.com", replacements: []} =
             PreservedTokens.protect(
               "https://example.com",
               PreservedTokens.resolve(["none"])
             )
  end

  test "masks double-brace placeholders as a single token" do
    protection = PreservedTokens.protect("Hello {{user.name}}", ["placeholders"])

    assert [{marker, "{{user.name}}"}] = protection.replacements
    assert marker =~ ~r/\A\{\{glossia_protected_[a-f0-9]{12}_0\}\}\z/
    assert protection.text == "Hello " <> marker
    assert {:ok, "Hello {{user.name}}"} = PreservedTokens.restore(protection.text, protection)
  end

  test "keeps markers shaped like the syntax they replace" do
    source = "Run `mix test` with {locale}.\n\n```elixir\nIO.puts(:ok)\n```"
    protection = PreservedTokens.protect(source, ~w(inline_code placeholders code_blocks))

    assert protection.text =~ ~r/`glossia_protected_[a-f0-9]{12}_0`/
    assert protection.text =~ ~r/\{glossia_protected_[a-f0-9]{12}_1\}/

    assert protection.text =~
             ~r/```glossia-protected\nglossia_protected_[a-f0-9]{12}_2\n```/

    assert {:ok, ^source} = PreservedTokens.restore(protection.text, protection)
  end
end
