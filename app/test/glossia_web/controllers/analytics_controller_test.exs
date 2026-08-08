defmodule GlossiaWeb.AnalyticsControllerTest do
  use GlossiaWeb.ConnCase, async: false

  import Ecto.Query

  alias Glossia.Analytics.Event
  alias Glossia.Analytics.Settings
  alias Glossia.ClickHouseRepo
  alias Glossia.Projects
  alias Glossia.TestHelpers

  setup do
    user = TestHelpers.create_user("collect@test.com", "collect")

    {:ok, project} =
      Projects.create_project(user.account, %{
        handle: "collect-#{System.unique_integer([:positive])}",
        name: "Collect Project",
        setup_target_languages: ["de", "fr"]
      })

    domain = "collect-#{System.unique_integer([:positive])}.com"
    {:ok, _settings} = Settings.upsert_for_project(project.id, %{domain: domain})

    %{project: project, domain: domain}
  end

  test "OPTIONS preflight returns 204 with CORS headers", %{conn: conn} do
    conn = options(conn, "/api/analytics/events")

    assert conn.status == 204
    assert get_resp_header(conn, "access-control-allow-origin") == ["*"]
  end

  test "records an enriched event for a known domain and returns 202", ctx do
    %{conn: conn, project: project, domain: domain} = ctx

    conn =
      conn
      |> put_req_header("user-agent", "Mozilla/5.0 (Windows NT 10.0; Win64; x64) Chrome/120.0")
      |> post("/api/analytics/events", %{
        "d" => domain,
        "u" => "https://#{domain}/pricing",
        "r" => "https://www.google.com/",
        "l" => "ja,en",
        "n" => "pageview"
      })

    assert conn.status == 202
    assert response(conn, 202) == ""

    # The write went through the sandboxed IngestRepo (write_through_repo),
    # so the row is visible to this test's read connection immediately.
    [event] =
      from(e in Event, where: e.hostname == ^domain)
      |> ClickHouseRepo.all()

    assert event.project_id == to_string(project.id)
    assert event.name == "pageview"
    assert event.pathname == "/pricing"
    assert event.referrer_source == "google.com"
    # Visitor prefers Japanese, project serves de/fr -> localization gap.
    assert event.browser_language == "ja"
    assert event.served_locale == ""
    assert event.has_locale_gap == 1
    assert event.browser == "Chrome"
    assert is_integer(event.visitor_id) and event.visitor_id > 0
  end

  test "returns 202 without recording for an unknown domain", %{conn: conn, domain: domain} do
    unknown = "not-registered-#{System.unique_integer()}.com"
    conn = post(conn, "/api/analytics/events", %{"d" => unknown})

    assert conn.status == 202

    # No row was written for the unknown domain. We also assert nothing was
    # written for the project's known domain, to catch accidental inserts.
    assert from(e in Event, where: e.hostname == ^unknown or e.hostname == ^domain)
           |> ClickHouseRepo.all() == []
  end

  test "returns 202 without recording when no domain can be resolved", %{conn: conn, domain: domain} do
    conn = post(conn, "/api/analytics/events", %{"n" => "pageview"})

    assert conn.status == 202

    assert from(e in Event, where: e.hostname == ^domain)
           |> ClickHouseRepo.all() == []
  end
end
