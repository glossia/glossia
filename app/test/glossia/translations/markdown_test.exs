defmodule Glossia.Translations.MarkdownTest do
  use ExUnit.Case, async: true

  alias Glossia.Translations.Markdown

  test "takes prose from the translation while retaining source link destinations and code" do
    source = "Read [the guide](https://example.com/guide) with `mix test`."

    translated =
      "Lee [la guía](https://example.com/es/guide) con `npm test`."

    assert {:ok, output} = Markdown.reconcile(source, translated)
    assert String.trim(output) == "Lee [la guía](https://example.com/guide) con `mix test`."
  end

  test "rejects a candidate that drops source link structure" do
    assert {:error, message} =
             Markdown.reconcile(
               "Read [the guide](https://example.com/guide).",
               "Lee la guía."
             )

    assert message =~ "changed the document structure"
  end

  test "retains a source heading when the translation makes it a bold paragraph" do
    assert {:ok, output} = Markdown.reconcile("## Next steps", "**다음 단계**")

    assert String.trim(output) == "## 다음 단계"
  end

  test "does not retain emphasis added around a plain source paragraph" do
    assert {:ok, output} = Markdown.reconcile("Read the guide.", "**가이드를 읽어보세요.**")

    assert String.trim(output) == "가이드를 읽어보세요."
  end

  test "rejects an empty candidate for Markdown without protected tokens" do
    assert {:error, message} =
             Markdown.reconcile(
               "# Retry setup\n\n- Check the model\n- Retry the project",
               ""
             )

    assert message =~ "changed the document structure"
  end

  test "rebuilds source Markdown from marker-delimited translated text" do
    source = "Read [the guide](https://example.com/guide)."

    assert {:ok, marked} = Markdown.mark_text_nodes(source)

    assert marked ==
             "@@GLOSSIA-TEXT-1-START@@Read @@GLOSSIA-TEXT-1-END@@[" <>
               "@@GLOSSIA-TEXT-2-START@@the guide@@GLOSSIA-TEXT-2-END@@]" <>
               "(https://example.com/guide)@@GLOSSIA-TEXT-3-START@@.@@GLOSSIA-TEXT-3-END@@"

    translated =
      "@@GLOSSIA-TEXT-1-START@@Lee @@GLOSSIA-TEXT-1-END@@" <>
        "@@GLOSSIA-TEXT-2-START@@la guía@@GLOSSIA-TEXT-2-END@@" <>
        "@@GLOSSIA-TEXT-3-START@@.@@GLOSSIA-TEXT-3-END@@"

    assert {:ok, output} = Markdown.reconcile_marked_text_nodes(source, translated)
    assert String.trim(output) == "Lee [la guía](https://example.com/guide)."
  end

  test "rejects an empty translation for a non-empty source text node" do
    source = "Keep this sentence.\n\nAlso keep this one."

    translated =
      "@@GLOSSIA-TEXT-1-START@@Guarda esta frase.@@GLOSSIA-TEXT-1-END@@\n\n" <>
        "@@GLOSSIA-TEXT-2-START@@@@GLOSSIA-TEXT-2-END@@"

    assert {:error, message} = Markdown.reconcile_marked_text_nodes(source, translated)
    assert message =~ "marker 2 had an empty translation"
  end

  test "rejects a missing whitespace text node" do
    source = "Read [the guide](https://example.com/guide) now."

    translated =
      "@@GLOSSIA-TEXT-1-START@@@@GLOSSIA-TEXT-1-END@@" <>
        "@@GLOSSIA-TEXT-2-START@@la guía@@GLOSSIA-TEXT-2-END@@" <>
        "@@GLOSSIA-TEXT-3-START@@ ahora.@@GLOSSIA-TEXT-3-END@@"

    assert {:error, message} = Markdown.reconcile_marked_text_nodes(source, translated)
    assert message =~ "marker 1 had an empty translation"
  end

  test "rejects whitespace-only output for a source text node with prose" do
    source = "Read [the guide](https://example.com/guide) now."

    translated =
      "@@GLOSSIA-TEXT-1-START@@ @@GLOSSIA-TEXT-1-END@@" <>
        "@@GLOSSIA-TEXT-2-START@@la guía@@GLOSSIA-TEXT-2-END@@" <>
        "@@GLOSSIA-TEXT-3-START@@ ahora.@@GLOSSIA-TEXT-3-END@@"

    assert {:error, message} = Markdown.reconcile_marked_text_nodes(source, translated)
    assert message =~ "marker 1 had an empty translation"
  end

  test "rejects interleaved recovery markers" do
    source = "Read [the guide](https://example.com/guide) now."

    translated =
      "@@GLOSSIA-TEXT-1-START@@Lee @@GLOSSIA-TEXT-2-START@@" <>
        "@@GLOSSIA-TEXT-1-END@@la guía@@GLOSSIA-TEXT-2-END@@" <>
        "@@GLOSSIA-TEXT-3-START@@ ahora.@@GLOSSIA-TEXT-3-END@@"

    assert {:error, message} = Markdown.reconcile_marked_text_nodes(source, translated)
    assert message =~ "missing, duplicated, or reordered"
  end

  test "round-trips escaped text literals without compounding escapes" do
    source =
      "Use snake_case, costs 5 \\* 3, and {__GLOSSIA_TOKEN_abc123def456_1} in " <>
        "[docs](https://example.com/docs)."

    assert {:ok, marked} = Markdown.mark_text_nodes(source)
    assert {:ok, expected} = Markdown.reconcile(source, source)
    assert {:ok, output} = Markdown.reconcile_marked_text_nodes(source, marked)
    assert output == expected
  end

  test "rebuilds Markdown from individually translated text literals" do
    source = "Read [the guide](https://example.com/guide).\n\nParagraph."

    assert {:ok, literals} = Markdown.text_literals(source)
    assert literals == ["Read ", "the guide", ".", "Paragraph."]

    assert {:ok, output} =
             Markdown.rebuild_text_literals(source, ["Lee ", "la guía", ".", "Párrafo."])

    assert String.trim(output) == "Lee [la guía](https://example.com/guide).\n\nPárrafo."
  end

  test "rejects an individually translated literal that erases source prose" do
    assert {:error, message} =
             Markdown.rebuild_text_literals("Keep this sentence.", ["   "])

    assert message =~ "emptied a source literal"
  end

  test "requires whitespace-only literals to remain byte-for-byte unchanged" do
    assert {:error, message} =
             Markdown.rebuild_text_literals("[guide](https://example.com) ", ["guide", "\n"])

    assert message =~ "emptied a source literal"
  end
end
