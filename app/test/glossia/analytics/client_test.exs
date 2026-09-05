defmodule Glossia.Analytics.ClientTest do
  use ExUnit.Case, async: true

  alias Glossia.Analytics.Client

  describe "parse_url/1" do
    test "extracts and downcases the hostname and keeps the path" do
      assert Client.parse_url("https://Example.COM/blog/post?x=1") ==
               %{hostname: "example.com", pathname: "/blog/post"}
    end

    test "defaults an empty or missing path to /" do
      assert Client.parse_url("https://example.com") == %{hostname: "example.com", pathname: "/"}
      assert Client.parse_url("https://example.com/") == %{hostname: "example.com", pathname: "/"}
    end

    test "returns empty hostname for nil or a url without a host" do
      assert Client.parse_url(nil) == %{hostname: "", pathname: "/"}
      assert Client.parse_url("not a url") == %{hostname: "", pathname: "/"}
    end
  end

  describe "parse_referrer/1" do
    test "returns the referrer and its source host without www./m. prefixes" do
      assert Client.parse_referrer("https://www.google.com/search?q=glossia") ==
               %{
                 referrer: "https://www.google.com/search?q=glossia",
                 referrer_source: "google.com"
               }

      assert Client.parse_referrer("https://m.facebook.com/") ==
               %{referrer: "https://m.facebook.com/", referrer_source: "facebook.com"}
    end

    test "returns empty values for nil, empty, or hostless referrers" do
      assert Client.parse_referrer(nil) == %{referrer: "", referrer_source: ""}
      assert Client.parse_referrer("") == %{referrer: "", referrer_source: ""}
      assert Client.parse_referrer("garbage") == %{referrer: "", referrer_source: ""}
    end
  end

  describe "parse_languages/1" do
    test "parses a comma-separated list into ordered normalized locales" do
      assert Client.parse_languages("en-US,en;q=0.9,de;q=0.8") == ["en-US", "en", "de"]
    end

    test "canonicalizes browser tags onto Glossia locales" do
      assert Client.parse_languages("zh-CN") == ["zh-Hans"]
      assert Client.parse_languages("zh-TW") == ["zh-Hant"]
      assert Client.parse_languages("pt") == ["pt-BR"]
      assert Client.parse_languages("pt-PT") == ["pt-PT"]
      assert Client.parse_languages("no") == ["nb"]
    end

    test "uppercases regions for tags without an explicit mapping" do
      assert Client.parse_languages("es-mx") == ["es-MX"]
      assert Client.parse_languages("fr") == ["fr"]
    end

    test "drops empty tokens and wildcards" do
      assert Client.parse_languages("*") == []
      assert Client.parse_languages("en,,*,de") == ["en", "de"]
    end

    test "returns an empty list for nil or empty input" do
      assert Client.parse_languages(nil) == []
      assert Client.parse_languages("") == []
    end
  end

  describe "localize/2" do
    test "returns the first matching target locale and reports no gap" do
      # served_locale is the first *target* that matches any preferred locale;
      # "de-DE" matches preferred "de" on its base language.
      assert Client.localize(["de", "en"], ["de-DE", "de", "fr"]) == {"de", "de-DE", 0}
      assert Client.localize(["de", "en"], ["de", "fr"]) == {"de", "de", 0}
    end

    test "matches on base language when the exact tag is absent" do
      assert Client.localize(["de-AT"], ["de"]) == {"de-AT", "de", 0}
    end

    test "flags a gap when the preferred language is not served" do
      assert Client.localize(["ja", "ko"], ["en", "de"]) == {"ja", "", 1}
    end

    test "reports no gap when the visitor stated no preference" do
      assert Client.localize([], ["en"]) == {"", "", 0}
    end
  end

  describe "parse_user_agent/1" do
    test "classifies a desktop Chrome user agent" do
      ua =
        "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 " <>
          "(KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"

      assert Client.parse_user_agent(ua) == %{device: "desktop", browser: "Chrome", os: "Windows"}
    end

    test "collapses mobile Safari onto Safari and reports a mobile device" do
      ua =
        "Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 " <>
          "(KHTML, like Gecko) Version/17.0 Mobile/15E148 Safari/604.1"

      assert Client.parse_user_agent(ua) == %{device: "mobile", browser: "Safari", os: "iOS"}
    end

    test "detects bots" do
      ua = "Mozilla/5.0 (compatible; Googlebot/2.1; +http://www.google.com/bot.html)"
      assert Client.parse_user_agent(ua) == %{device: "bot", browser: "bot", os: "unknown"}
    end

    test "returns unknowns for a nil user agent" do
      assert Client.parse_user_agent(nil) == %{
               device: "unknown",
               browser: "unknown",
               os: "unknown"
             }
    end
  end
end
