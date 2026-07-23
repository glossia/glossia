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

    refute protection.text =~ "https://example.com/guide"
    refute protection.text =~ "IO.puts"
    refute protection.text =~ "{locale}"

    translated = String.replace(protection.text, "Read", "Lee")
    assert {:ok, restored} = PreservedTokens.restore(translated, protection)
    assert restored =~ "[the guide](https://example.com/guide)"
    assert restored =~ "`{locale}`"
    assert restored =~ "IO.puts(\"https://inside.example\")"
  end

  test "reports a missing or duplicated marker" do
    protection = PreservedTokens.protect("Visit https://example.com.", ["urls"])
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
    assert protection.text == "Hello " <> marker
    assert {:ok, "Hello {{user.name}}"} = PreservedTokens.restore(protection.text, protection)
  end
end
