defmodule GlossiaWeb.AnalyticsControllerTest do
  use GlossiaWeb.ConnCase, async: false

  use Mimic

  alias Glossia.Analytics.Ingestion
  alias Glossia.Analytics.Settings
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
    conn = options(conn, "/v1/collect")

    assert conn.status == 204
    assert get_resp_header(conn, "access-control-allow-origin") == ["*"]
  end

  test "records an enriched event for a known domain and returns 202", ctx do
    %{conn: conn, project: project, domain: domain} = ctx
    test_pid = self()

    Mimic.expect(Ingestion, :record_event, fn event ->
      send(test_pid, {:recorded, event})
      :ok
    end)

    conn =
      conn
      |> put_req_header("user-agent", "Mozilla/5.0 (Windows NT 10.0; Win64; x64) Chrome/120.0")
      |> post("/v1/collect", %{
        "d" => domain,
        "u" => "https://#{domain}/pricing",
        "r" => "https://www.google.com/",
        "l" => "ja,en",
        "n" => "pageview"
      })

    assert conn.status == 202
    assert response(conn, 202) == ""

    assert_receive {:recorded, event}
    assert event.project_id == project.id
    assert event.name == "pageview"
    assert event.pathname == "/pricing"
    assert event.referrer_source == "google.com"
    # Visitor prefers Japanese, project serves de/fr -> localization gap.
    assert event.browser_language == "ja"
    assert event.has_locale_gap == 1
    assert event.browser == "Chrome"
    assert is_integer(event.visitor_id)
  end

  test "returns 202 without recording for an unknown domain", %{conn: conn} do
    Mimic.reject(&Ingestion.record_event/1)

    conn = post(conn, "/v1/collect", %{"d" => "not-registered-#{System.unique_integer()}.com"})

    assert conn.status == 202
  end

  test "returns 202 without recording when no domain can be resolved", %{conn: conn} do
    Mimic.reject(&Ingestion.record_event/1)

    conn = post(conn, "/v1/collect", %{"n" => "pageview"})

    assert conn.status == 202
  end
end
