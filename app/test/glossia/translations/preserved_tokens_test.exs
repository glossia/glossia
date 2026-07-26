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

  test "masks web addresses with address-shaped markers" do
    protection =
      PreservedTokens.protect(
        "Follow [Anthropic](https://anthropic.com) closely.",
        ["urls"]
      )

    [{marker, "https://anthropic.com"}] = protection.replacements

    assert marker =~
             ~r|\Ahttps://glossia\.invalid/protected-token/[a-f0-9]{12}/0/value\z|

    assert protection.text == "Follow [Anthropic](#{marker}) closely."

    assert {:ok, "Sigue [Anthropic](https://anthropic.com) de cerca."} =
             protection.text
             |> String.replace("Follow", "Sigue")
             |> String.replace(" closely.", " de cerca.")
             |> PreservedTokens.restore(protection)
  end

  test "masks repeated web addresses independently and restores every occurrence" do
    source =
      "Compare [one](https://anthropic.com) with [two](https://anthropic.com)."

    protection = PreservedTokens.protect(source, ["urls"])

    assert [{first, "https://anthropic.com"}, {second, "https://anthropic.com"}] =
             protection.replacements

    assert first != second
    refute protection.text =~ "https://anthropic.com"
    assert protection.text =~ "[one](#{first})"
    assert protection.text =~ "[two](#{second})"

    assert {:ok, "Compara [uno](https://anthropic.com) con [dos](https://anthropic.com)."} =
             protection.text
             |> String.replace("Compare", "Compara")
             |> String.replace("[one]", "[uno]")
             |> String.replace(" with ", " con ")
             |> String.replace("[two]", "[dos]")
             |> PreservedTokens.restore(protection)
  end

  test "keeps address markers prefix-safe after the tenth occurrence" do
    source =
      0..11
      |> Enum.map_join(" ", fn index -> "https://example.com/#{index}" end)

    protection = PreservedTokens.protect(source, ["urls"])

    assert length(protection.replacements) == 12
    assert {:ok, ^source} = PreservedTokens.restore(protection.text, protection)
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
