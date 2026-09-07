defmodule Glossia.I18nTest do
  use ExUnit.Case, async: true

  alias Glossia.I18n

  doctest Glossia.I18n

  describe "normalize/1" do
    test "keeps locales we serve" do
      assert I18n.normalize("es") == "es"
      assert I18n.normalize("pt-BR") == "pt-BR"
    end

    test "is case insensitive" do
      assert I18n.normalize("PT-br") == "pt-BR"
      assert I18n.normalize("ZH-hans") == "zh-Hans"
    end

    test "maps the tags browsers send onto the locale we ship" do
      assert I18n.normalize("es-419") == "es"
      assert I18n.normalize("zh-CN") == "zh-Hans"
      assert I18n.normalize("pt") == "pt-BR"
    end

    test "returns nil for languages we do not serve" do
      assert I18n.normalize("sv") == nil
      assert I18n.normalize("") == nil
      assert I18n.normalize(nil) == nil
    end
  end

  describe "from_accept_language/1" do
    test "picks the highest quality language we serve" do
      assert I18n.from_accept_language("de;q=0.4,ja;q=0.9,en;q=0.1") == "ja"
    end

    test "treats a missing quality as the strongest preference" do
      assert I18n.from_accept_language("fr,de;q=0.9") == "fr"
    end

    test "skips languages we do not serve" do
      assert I18n.from_accept_language("sv-SE,sv;q=0.9,es;q=0.5") == "es"
    end

    test "returns nil when nothing matches" do
      assert I18n.from_accept_language("sv-SE,sv;q=0.9") == nil
      assert I18n.from_accept_language(nil) == nil
    end
  end

  describe "localize_path/2 and split_path/1" do
    test "leaves English unprefixed" do
      assert I18n.localize_path("en", "/blog") == "/blog"
      assert I18n.localize_path("en", "/") == "/"
    end

    test "prefixes translated locales with their URL segment" do
      assert I18n.localize_path("es", "/blog/hello") == "/es/blog/hello"
      assert I18n.localize_path("pt-BR", "/docs") == "/pt-br/docs"
      assert I18n.localize_path("zh-Hans", "/") == "/zh-hans"
    end

    test "round-trips through split_path/1" do
      for locale <- I18n.locales(), path <- ["/", "/blog", "/docs/how-to/x"] do
        assert I18n.split_path(I18n.localize_path(locale, path)) == {locale, path}
      end
    end

    test "keeps query strings and fragments intact" do
      assert I18n.localize_path("es", "/blog?page=2") == "/es/blog?page=2"
      assert I18n.localize_path("es", "/changelog#v1") == "/es/changelog#v1"
      assert I18n.split_path("/es/blog?page=2") == {"es", "/blog?page=2"}
    end

    test "refuses to touch anything that is not a local path" do
      assert I18n.localize_path("es", "https://example.com/blog") ==
               "https://example.com/blog"

      assert I18n.localize_path("es", "//example.com/blog") == "//example.com/blog"

      assert I18n.split_path("https://example.com/es/blog") ==
               {"en", "https://example.com/es/blog"}
    end

    test "reads an unprefixed path as English" do
      assert I18n.split_path("/blog") == {"en", "/blog"}
      assert I18n.split_path("/pepicrft/website") == {"en", "/pepicrft/website"}
    end
  end

  test "every locale has a segment that maps back to it" do
    for locale <- I18n.locales() do
      assert locale |> I18n.segment() |> I18n.from_segment() == locale
      assert I18n.native_name(locale) != locale
    end
  end
end
