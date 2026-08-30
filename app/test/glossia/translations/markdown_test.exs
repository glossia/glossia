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
end
