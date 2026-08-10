defmodule GlossiaWeb.WebAnalyticsTest do
  # Not async: mutates the :web_analytics application env.
  use ExUnit.Case, async: false

  alias GlossiaWeb.WebAnalytics

  setup do
    original = Application.get_env(:glossia, :web_analytics)
    on_exit(fn -> Application.put_env(:glossia, :web_analytics, original) end)
    :ok
  end

  test "renders an empty safe string when no domain is configured" do
    Application.put_env(:glossia, :web_analytics, domain: nil)
    assert WebAnalytics.snippet() == {:safe, ""}
  end

  test "renders the script tag with the configured domain" do
    Application.put_env(:glossia, :web_analytics, domain: "example.com")

    assert {:safe, html} = WebAnalytics.snippet()
    assert html =~ ~s(src="/assets/glossia-web.js")
    assert html =~ ~s(data-domain="example.com")
    assert html =~ "defer"
  end

  test "html-escapes the configured domain" do
    Application.put_env(:glossia, :web_analytics, domain: ~s(a"><script>x))

    assert {:safe, html} = WebAnalytics.snippet()
    refute html =~ ~s(domain="a"><script>x)
    assert html =~ "&quot;"
  end
end
