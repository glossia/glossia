defmodule Glossia.Translations.PoTest do
  use ExUnit.Case, async: true

  alias Glossia.Translations.Po

  @header ~S|msgid ""
msgstr ""
"Language: ja\n"
"Plural-Forms: nplurals=1; plural=0;\n"
|

  test "drops the plural forms a catalog does not declare" do
    catalog =
      @header <>
        ~S|
#: lib/app.ex:1
msgid "%{count} language selected"
msgid_plural "%{count} languages selected"
msgstr[0] "1つの言語"
msgstr[1] "2つの言語"
|

    normalized = Po.normalize_plural_forms(catalog, "ja")

    assert normalized =~ ~S|msgstr[0] "1つの言語"|
    refute normalized =~ "msgstr[1]"
    # The comment that introduced the entry has to survive the rewrite.
    assert normalized =~ "#: lib/app.ex:1"
  end

  test "pads a catalog that came back with too few forms" do
    catalog =
      ~S|msgid ""
msgstr ""
"Plural-Forms: nplurals=2; plural=(n != 1);\n"

msgid "%{count} file"
msgid_plural "%{count} files"
msgstr[0] "%{count} fichier"
|

    normalized = Po.normalize_plural_forms(catalog, "fr")

    assert normalized =~ ~S|msgstr[0] "%{count} fichier"|
    assert normalized =~ ~S|msgstr[1] "%{count} fichier"|
  end

  test "keeps a catalog that already matches byte for byte" do
    catalog =
      ~S|msgid ""
msgstr ""
"Plural-Forms: nplurals=2; plural=(n != 1);\n"

msgid "%{count} file"
msgid_plural "%{count} files"
msgstr[0] "%{count} archivo"
msgstr[1] "%{count} archivos"
|

    assert Po.normalize_plural_forms(catalog, "es") == catalog
  end

  test "carries the continuation lines of a form it keeps or drops" do
    catalog =
      @header <>
        ~S|
msgid "long"
msgid_plural "longs"
msgstr[0] ""
"first form "
"continued"
msgstr[1] ""
"second form"
|

    normalized = Po.normalize_plural_forms(catalog, "ja")

    assert normalized =~ ~S|"first form "|
    assert normalized =~ ~S|"continued"|
    refute normalized =~ "second form"
  end

  test "leaves a catalog alone when it declares no plural forms" do
    catalog = ~S|msgid "hello"
msgstr "hola"
|

    assert Po.normalize_plural_forms(catalog, nil) == catalog
  end
end
