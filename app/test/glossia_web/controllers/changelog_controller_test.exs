defmodule GlossiaWeb.ChangelogControllerTest do
  use GlossiaWeb.ConnCase, async: true

  test "lists changelog entries with their details", %{conn: conn} do
    html = conn |> get(~p"/changelog") |> html_response(200)

    assert html =~ ~s(id="calmer-translation-pull-requests")
    assert html =~ "Calmer translation pull requests"
    assert html =~ "You learn a lot the first time your tool meets a real repository."
  end

  test "publishes the entries in the feed", %{conn: conn} do
    feed = conn |> get(~p"/changelog/feed.xml") |> response(200)

    assert feed =~ "Calmer translation pull requests"
  end
end
