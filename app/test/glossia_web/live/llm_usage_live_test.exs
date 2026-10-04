defmodule GlossiaWeb.LLMUsageLiveTest do
  use GlossiaWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  alias Glossia.Accounts.Project
  alias Glossia.Repo
  alias Glossia.TestHelpers
  alias Glossia.Translations.TokenUsage

  setup %{conn: conn} do
    user = TestHelpers.create_user("usage-ui@test.com", "usage-ui")
    project = Repo.insert!(%Project{account_id: user.account.id, handle: "docs", name: "Docs"})

    :ok =
      TokenUsage.record(
        %{
          account_id: user.account.id,
          project_id: project.id,
          model: "openai/gpt-4o",
          source_path: "guide.md",
          locale: "es"
        },
        %{input_tokens: 1000, output_tokens: 250, cached_tokens: 100}
      )

    %{conn: init_test_session(conn, %{user_id: user.id}), user: user, project: project}
  end

  test "models links to usage and dimensions share the same totals", %{conn: conn, user: user} do
    path = "/#{user.account.handle}/-/settings/models/usage"
    {:ok, models, _} = live(conn, "/#{user.account.handle}/-/settings/models")
    assert has_element?(models, "a[href='#{path}']", "Token usage")

    {:ok, view, html} = live(conn, path)
    assert html =~ "1,250"
    assert has_element?(view, "#token-usage-chart")

    chart =
      html
      |> LazyHTML.from_document()
      |> LazyHTML.query("#token-usage-chart [data-part='data']")
      |> LazyHTML.text()
      |> JSON.decode!()

    assert chart["grid"] == %{
             "left" => "2%",
             "right" => 0,
             "top" => "15%",
             "bottom" => 0,
             "containLabel" => true
           }

    assert chart["yAxis"]["splitNumber"] == 4
    assert Enum.all?(chart["xAxis"]["data"], &Regex.match?(~r/^[A-Z][a-z]{2} \d{1,2}$/, &1))
    assert has_element?(view, "#token-usage-table", "docs")

    view |> element("a", "Languages") |> render_click()
    assert_patch(view, path <> "?dimension=languages&page=1")
    assert has_element?(view, "#token-usage-table", "es")

    view |> element("a", "Files") |> render_click()
    assert has_element?(view, "#token-usage-table", "guide.md")
    assert has_element?(view, "#token-usage-table", "docs")
    assert render(view) =~ "1,250"
  end

  test "search, period, and sorting survive URL navigation", %{conn: conn, user: user} do
    path = "/#{user.account.handle}/-/settings/models/usage"
    {:ok, view, _} = live(conn, path <> "?dimension=files&days=7&sort=label&dir=asc")
    assert has_element?(view, "#usage-days option[value='7'][selected]")
    view |> form("#usage-search", %{q: "missing"}) |> render_change()
    assert has_element?(view, "#token-usage-table", "No reported usage")
    assert render(view) =~ "1,250"
    view |> form("#usage-period", %{days: "90"}) |> render_change()
    assert has_element?(view, "#usage-days option[value='90'][selected]")
  end

  test "Noora model filters apply to the entire usage scope", %{conn: conn, user: user} do
    :ok =
      TokenUsage.record(
        %{
          account_id: user.account.id,
          model: "unknown/model",
          inserted_at: DateTime.add(DateTime.utc_now(), -100 * 86400, :second)
        },
        %{input_tokens: 10, output_tokens: 10}
      )

    {:ok, view, _} = live(conn, "/#{user.account.handle}/-/settings/models/usage")
    render_hook(view, "add_filter", %{"value" => "model"})

    render_hook(view, "update_filter", %{
      "type" => "change_value",
      "payload_filter_id" => "model",
      "value" => "openai/gpt-4o"
    })

    assert render(view) =~ "1,250"

    render_hook(view, "update_filter", %{
      "type" => "change_value",
      "payload_filter_id" => "model",
      "value" => "unknown/model"
    })

    assert has_element?(view, "#token-usage-table", "No reported usage")
    refute has_element?(view, "#token-usage-chart")
  end

  test "missing sessions return to usage after sign in", %{user: user} do
    path = "/#{user.account.handle}/-/settings/models/usage"
    conn = build_conn() |> get(path)
    assert redirected_to(conn) == "/auth/login"
    assert get_session(conn, :return_to) == path
  end

  test "another account cannot read usage", %{conn: conn} do
    other = TestHelpers.create_user("private-usage@test.com", "private-usage")
    assert_error_sent 404, fn -> get(conn, "/#{other.account.handle}/-/settings/models/usage") end
  end
end
