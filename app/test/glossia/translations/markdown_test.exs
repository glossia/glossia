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

  test "rejects an empty candidate for Markdown without protected tokens" do
    assert {:error, message} =
             Markdown.reconcile(
               "# Retry setup\n\n- Check the model\n- Retry the project",
               ""
             )

    assert message =~ "changed the document structure"
  end
end
