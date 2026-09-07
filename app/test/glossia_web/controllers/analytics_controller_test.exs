defmodule GlossiaWeb.AnalyticsControllerTest do
  use GlossiaWeb.ConnCase, async: false

  import Ecto.Query
  import ExUnit.CaptureLog
  import Mimic

  alias Glossia.Analytics.Event
  alias Glossia.Analytics.Ingestion
  alias Glossia.Analytics.Queries
  alias Glossia.Analytics.Settings
  alias Glossia.ClickHouseRepo
  alias Glossia.Projects
  alias Glossia.TestHelpers

  setup :verify_on_exit!

  defmodule GeolocationAdapter do
    @behaviour Glossia.Analytics.Geolocation

    @impl true
    def lookup("8.8.8.8"), do: %{country: "DE"}
    def lookup(_ip), do: %{country: nil}
  end

  setup do
    user = TestHelpers.create_user("collect@test.com", "collect")

    {:ok, project} =
      Projects.create_project(user.account, %{
        handle: "collect-#{System.unique_integer([:positive])}",
        name: "Collect Project",
        setup_target_languages: ["de", "fr"]
      })

    domain = "collect-#{System.unique_integer([:positive])}.com"
    {:ok, settings} = Settings.upsert_for_project(project.id, %{domain: domain})

    # Collection only accepts verified domains, so stamp `verified_at` the way
    # `Settings.verify_for_project/1` does once ownership has been proven.
    {:ok, _verified} =
      settings
      |> Ecto.Changeset.change(%{
        verified_at: DateTime.utc_now() |> DateTime.truncate(:microsecond)
      })
      |> Glossia.Repo.update()

    %{project: project, domain: domain}
  end

  test "OPTIONS preflight returns 204 with CORS headers", %{conn: conn} do
    conn = options(conn, "/api/analytics/events")

    assert conn.status == 204
    assert get_resp_header(conn, "access-control-allow-origin") == ["*"]
  end

  test "public collection route accepts analytics events", %{conn: conn, domain: domain} do
    conn =
      post(conn, "/v1/collect", %{
        "d" => domain,
        "u" => "https://#{domain}/",
        "n" => "pageview"
      })

    assert conn.status == 202
  end

  test "reports collection failures while preserving the accepted response", %{
    conn: conn,
    domain: domain
  } do
    expect(Ingestion, :record_event, fn _event -> raise RuntimeError, "write failed" end)

    log =
      capture_log(fn ->
        conn = post(conn, "/v1/collect", %{"d" => domain, "u" => "https://#{domain}/"})
        assert conn.status == 202
      end)

    assert log =~ "Analytics collection failed"
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
        "n" => "pageview",
        "sw" => 1_440
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
    assert event.screen_width == 1_440
    assert is_integer(event.visitor_id) and event.visitor_id > 0

    now = DateTime.utc_now()
    summary = Queries.summary(project.id, DateTime.add(now, -60), DateTime.add(now, 60))
    assert summary.top_country == ""
    assert summary.top_browser_language == "ja"

    assert Queries.top_countries(project.id,
             since: DateTime.add(now, -60),
             until: DateTime.add(now, 60)
           ) == []
  end

  test "falls back to the socket address when the forwarded address is malformed", ctx do
    %{conn: conn, project: project, domain: domain} = ctx
    original_config = Application.get_env(:glossia, Glossia.Analytics, [])

    Application.put_env(
      :glossia,
      Glossia.Analytics,
      Keyword.put(original_config, :geolocation, adapter: GeolocationAdapter)
    )

    on_exit(fn -> Application.put_env(:glossia, Glossia.Analytics, original_config) end)

    conn =
      conn
      |> Map.put(:remote_ip, {8, 8, 8, 8})
      |> put_req_header("x-forwarded-for", "not-an-address")
      |> post("/v1/collect", %{
        "d" => domain,
        "u" => "https://#{domain}/country"
      })

    assert conn.status == 202

    [event] =
      from(e in Event, where: e.hostname == ^domain and e.pathname == "/country")
      |> ClickHouseRepo.all()

    assert event.country_code == "DE"

    now = DateTime.utc_now()

    assert Queries.top_countries(project.id,
             since: DateTime.add(now, -60),
             until: DateTime.add(now, 60)
           ) == [%{country_code: "DE", visits: 1}]
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

  test "returns 202 without recording when no domain can be resolved", %{
    conn: conn,
    domain: domain
  } do
    conn = post(conn, "/api/analytics/events", %{"n" => "pageview"})

    assert conn.status == 202

    assert from(e in Event, where: e.hostname == ^domain)
           |> ClickHouseRepo.all() == []
  end
end
