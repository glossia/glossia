defmodule Glossia.Translations.PoTest do
  use ExUnit.Case, async: true

  alias Glossia.Translations.Po

  describe "text_literals/1 + rebuild_text_literals/2" do
    test "extracts msgstrs from a simple catalog and rebuilds with translations" do
      source = """
      msgid ""
      msgstr ""
      "Language: es\\n"
      "Content-Type: text/plain; charset=UTF-8\\n"

      msgid "Hello"
      msgstr ""

      msgid "Goodbye"
      msgstr ""
      """

      assert {:ok, literals} = Po.text_literals(source)

      # header msgstr + Hello + Goodbye
      assert length(literals) == 3
      assert "Language: es" in Enum.map(literals, &String.slice(&1, 0..11))
      assert Enum.member?(literals, "Hello")
      assert Enum.member?(literals, "Goodbye")

      # Model returns translations in the same order
      translated = ["Language: es\nContent-Type: text/plain; charset=UTF-8\n", "Hola", "Adiós"]
      assert {:ok, output} = Po.rebuild_text_literals(source, translated)

      assert output =~ ~s(msgid "Hello")
      assert output =~ ~s(msgstr "Hola")
      assert output =~ ~s(msgid "Goodbye")
      assert output =~ ~s(msgstr "Adiós")
    end

    test "translates the source msgid when msgstr is empty (template catalog)" do
      source = """
      msgid ""
      msgstr ""

      msgid "Welcome to Glossia"
      msgstr ""
      """

      assert {:ok, ["", "Welcome to Glossia"]} = Po.text_literals(source)
    end

    test "translates the source msgstr when it is already filled" do
      # A source catalog where the developer wrote a source-language msgstr —
      # translate what's there, not the msgid.
      source = """
      msgid ""
      msgstr ""

      msgid "welcome_key"
      msgstr "Welcome to Glossia"
      """

      assert {:ok, ["", "Welcome to Glossia"]} = Po.text_literals(source)
    end

    test "preserves comments (translator, references, flags) verbatim" do
      source = """
      msgid ""
      msgstr ""

      #. This is the greeting on the home page
      #: lib/welcome.ex:42
      #, elixir-autogen, elixir-format
      msgid "Hello"
      msgstr ""
      """

      {:ok, literals} = Po.text_literals(source)
      {:ok, output} = Po.rebuild_text_literals(source, List.duplicate("Hola", length(literals)))

      assert output =~ "#. This is the greeting"
      assert output =~ "#: lib/welcome.ex:42"
      assert output =~ "#, elixir-autogen, elixir-format"
    end

    test "preserves plural forms and translates each form's msgstr" do
      source = """
      msgid ""
      msgstr ""
      "Plural-Forms: nplurals=2; plural=(n != 1);\\n"

      msgid "%{count} file"
      msgid_plural "%{count} files"
      msgstr[0] ""
      msgstr[1] ""
      """

      {:ok, literals} = Po.text_literals(source)
      # header + msgid (form 0) + msgid_plural (form 1) = 3
      assert length(literals) == 3

      translated = [Enum.at(literals, 0), "%{count} archivo", "%{count} archivos"]
      {:ok, output} = Po.rebuild_text_literals(source, translated)

      assert output =~ ~s(msgstr[0] "%{count} archivo")
      assert output =~ ~s(msgstr[1] "%{count} archivos")
    end

    test "skips obsolete entries (#~) and preserves them verbatim in the output" do
      source = """
      msgid ""
      msgstr ""

      msgid "New key"
      msgstr ""

      #~ msgid "Old key"
      #~ msgstr "Old translation"
      """

      {:ok, literals} = Po.text_literals(source)
      # header + New key only — obsolete entry is excluded from literals
      assert length(literals) == 2

      translated = [Enum.at(literals, 0), "Nueva clave"]
      {:ok, output} = Po.rebuild_text_literals(source, translated)

      assert output =~ "#~ msgid \"Old key\""
      assert output =~ "#~ msgstr \"Old translation\""
      assert output =~ ~s(msgstr "Nueva clave")
    end

    test "reassembles multi-line quoted source strings into single-line output" do
      source = """
      msgid ""
      msgstr ""

      msgid ""
      "This is a long "
      "source string."
      msgstr ""
      """

      {:ok, literals} = Po.text_literals(source)
      # header + long string
      assert length(literals) == 2
      assert Enum.at(literals, 1) == "This is a long source string."

      {:ok, output} =
        Po.rebuild_text_literals(source, [Enum.at(literals, 0), "Es una cadena larga."])

      assert output =~ ~s(msgstr "Es una cadena larga.")
    end

    test "returns an error when the translations length does not match" do
      source = ~s(msgid ""\nmsgstr ""\n\nmsgid "Hello"\nmsgstr ""\n)
      assert {:error, message} = Po.rebuild_text_literals(source, ["only-one"])
      assert message =~ "expected"
    end

    test "escapes quotes and real newlines in translated content" do
      source = ~s(msgid ""\nmsgstr ""\n\nmsgid "Cancel"\nmsgstr ""\n)
      # Use a real newline in the translated string; it should be emitted as
      # the two-character escape `\n` inside the quoted msgstr.
      {:ok, output} = Po.rebuild_text_literals(source, ["", ~s(He said "hello"\n)])
      assert output =~ ~s(msgstr "He said \\"hello\\"\\n")
    end
  end

  describe "translation_units/1" do
    test "returns one unit per translatable entry, keyed by msgid identity" do
      source = """
      msgid ""
      msgstr "Language: es\\n"

      msgid "Hello"
      msgstr ""

      msgid "Goodbye"
      msgstr ""
      """

      assert {:ok, [header, hello, goodbye]} = Po.translation_units(source)

      assert header.sources == ["Language: es\n"]
      assert header.literal_offset == 0

      assert hello.sources == ["Hello"]
      assert hello.literal_offset == 1

      assert goodbye.sources == ["Goodbye"]
      assert goodbye.literal_offset == 2

      # Every unit's key is a stable hex digest.
      for unit <- [header, hello, goodbye] do
        assert is_binary(unit.key) and String.length(unit.key) == 64
        assert is_binary(unit.source_hash) and String.length(unit.source_hash) == 64
      end

      assert hello.key != goodbye.key
    end

    test "one unit per plural entry, with one source per plural form" do
      source = """
      msgid ""
      msgstr ""

      msgid "%d file"
      msgid_plural "%d files"
      msgstr[0] ""
      msgstr[1] ""
      """

      assert {:ok, [_header, plural]} = Po.translation_units(source)
      assert plural.sources == ["%d file", "%d files"]
    end

    test "source_hash only tracks the strings we translate" do
      base = """
      msgid ""
      msgstr ""

      msgid "Hello"
      msgstr ""
      """

      referenced = """
      msgid ""
      msgstr ""

      #: lib/a.ex:12 lib/b.ex:900
      msgid "Hello"
      msgstr ""
      """

      {:ok, [_, base_hello]} = Po.translation_units(base)
      {:ok, [_, ref_hello]} = Po.translation_units(referenced)

      # References/comments do not affect the source hash. This is what lets
      # a `.pot` regeneration that only shifts references skip re-translation.
      assert base_hello.source_hash == ref_hello.source_hash
      assert base_hello.key == ref_hello.key
    end

    test "skips obsolete entries" do
      source = """
      msgid ""
      msgstr ""

      msgid "Hello"
      msgstr ""

      #~ msgid "Removed"
      #~ msgstr ""
      """

      assert {:ok, [_header, hello]} = Po.translation_units(source)
      assert hello.sources == ["Hello"]
    end
  end

  describe "output_translations/1" do
    test "maps unit keys to their existing msgstrs" do
      source = """
      msgid ""
      msgstr ""

      msgid "Hello"
      msgstr ""

      msgid "%d file"
      msgid_plural "%d files"
      msgstr[0] ""
      msgstr[1] ""
      """

      output = """
      msgid ""
      msgstr "Language: es\\n"

      msgid "Hello"
      msgstr "Hola"

      msgid "%d file"
      msgid_plural "%d files"
      msgstr[0] "%d archivo"
      msgstr[1] "%d archivos"
      """

      {:ok, [header_unit, hello_unit, plural_unit]} = Po.translation_units(source)
      {:ok, output_translations} = Po.output_translations(output)

      assert output_translations[header_unit.key] == ["Language: es\n"]
      assert output_translations[hello_unit.key] == ["Hola"]
      assert output_translations[plural_unit.key] == ["%d archivo", "%d archivos"]
    end
  end
end
