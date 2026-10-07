defmodule GlossiaWeb.ChangelogControllerTest do
  use GlossiaWeb.ConnCase, async: true

  test "lists changelog entries with their details", %{conn: conn} do
    html = conn |> get(~p"/changelog") |> html_response(200)

    assert html =~ ~s(id="translation-pull-requests-you-can-review")
    assert html =~ "Translation pull requests you can review"
    assert html =~ "One pull request that stays current"
  end

  test "publishes the entries in the feed", %{conn: conn} do
    feed = conn |> get(~p"/changelog/feed.xml") |> response(200)

    assert feed =~ "Translation pull requests you can review"
  end
end
