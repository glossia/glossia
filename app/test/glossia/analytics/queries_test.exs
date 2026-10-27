defmodule Glossia.Analytics.QueriesTest do
  use Glossia.DataCase, async: false

  alias Glossia.Analytics.Event
  alias Glossia.Analytics.Queries
  alias Glossia.IngestRepo

  test "every dashboard query honors the selected period" do
    project_id = Ecto.UUID.generate()
    since = datetime("2026-08-16T10:30:00Z")
    until = datetime("2026-08-16T12:00:00Z")

    insert_events([
      event(project_id, datetime("2026-08-16T11:15:00Z"), %{
        pathname: "/inside",
        country_code: "DE",
        browser_language: "ja",
        served_locale: "en",
        has_locale_gap: 1,
        visitor_id: 1
      }),
      event(project_id, datetime("2026-08-16T09:45:00Z"), %{
        pathname: "/outside",
        country_code: "FR",
        browser_language: "fr",
        has_locale_gap: 1,
        visitor_id: 2
      })
    ])

    summary = Queries.summary(project_id, since, until)
    assert summary.pageviews == 1
    assert summary.unique_visitors == 1
    assert summary.locale_gap_visits == 1
    assert summary.top_country == "DE"
    assert summary.top_browser_language == "ja"

    opts = [since: since, until: until]
    assert Queries.top_pages(project_id, opts) == [%{pathname: "/inside", pageviews: 1}]
    assert Queries.top_countries(project_id, opts) == [%{country_code: "DE", visits: 1}]

    assert Queries.browser_languages(project_id, ["en"], opts) == [
             %{
               browser_language: "ja",
               served_locale: "en",
               has_locale_gap: 1,
               visits: 1,
               is_served: false
             }
           ]

    assert [%{country_code: "DE", browser_language: "ja", visitors: 1}] =
             Queries.localization_priority(project_id, ["en"], opts)

    traffic = Queries.traffic(project_id, opts)
    assert traffic.granularity == "hour"

    assert Enum.map(traffic.points, & &1.bucket) == [
             "2026-08-16T10:00:00Z",
             "2026-08-16T11:00:00Z"
           ]

    assert Enum.map(traffic.points, & &1.pageviews) == [0, 1]

    daily_traffic =
      Queries.traffic(project_id,
        since: datetime("2026-08-01T00:00:00Z"),
        until: datetime("2026-08-17T00:00:00Z")
      )

    assert daily_traffic.granularity == "day"
    assert Enum.sum(Enum.map(daily_traffic.points, & &1.pageviews)) == 2

    assert %{pageviews: 2} =
             Enum.find(daily_traffic.points, &(&1.bucket == "2026-08-16T00:00:00Z"))

    monthly_traffic =
      Queries.traffic(project_id,
        since: datetime("2026-01-01T00:00:00Z"),
        until: datetime("2026-09-01T00:00:00Z")
      )

    assert monthly_traffic.granularity == "month"
    assert Enum.sum(Enum.map(monthly_traffic.points, & &1.pageviews)) == 2

    assert %{pageviews: 2} =
             Enum.find(monthly_traffic.points, &(&1.bucket == "2026-08-01T00:00:00Z"))
  end

  test "browser languages omits unreported languages before applying the limit" do
    project_id = Ecto.UUID.generate()
    since = datetime("2026-08-16T10:00:00Z")
    until = datetime("2026-08-16T12:00:00Z")
    inserted_at = datetime("2026-08-16T11:00:00Z")

    insert_events([
      event(project_id, inserted_at, %{browser_language: "en-US", served_locale: ""}),
      event(project_id, inserted_at, %{browser_language: "en-US", served_locale: ""}),
      event(project_id, inserted_at, %{browser_language: "", served_locale: "en"}),
      event(project_id, inserted_at, %{browser_language: "", served_locale: "en"}),
      event(project_id, inserted_at, %{browser_language: "en-US", served_locale: "en"})
    ])

    assert Queries.browser_languages(project_id, ["en"],
             since: since,
             until: until,
             limit: 1
           ) == [
             %{
               browser_language: "en-US",
               served_locale: "en",
               has_locale_gap: 0,
               visits: 1,
               is_served: false
             }
           ]
  end

  test "browser languages is empty when no page languages were reported" do
    project_id = Ecto.UUID.generate()
    since = datetime("2026-08-16T10:00:00Z")
    until = datetime("2026-08-16T12:00:00Z")

    insert_events([
      event(project_id, datetime("2026-08-16T11:00:00Z"), %{served_locale: ""})
    ])

    assert Queries.browser_languages(project_id, ["en"], since: since, until: until) == []
  end

  test "gap reporting uses stored decisions for explicit choices and historical events" do
    project_id = Ecto.UUID.generate()
    since = datetime("2026-08-16T10:00:00Z")
    until = datetime("2026-08-16T12:00:00Z")
    inserted_at = datetime("2026-08-16T11:00:00Z")

    # The last row predates choice-aware gap calculation. Neither it nor the
    # row without a selection can be recomputed from today's project targets:
    # historical advertised translations and full browser preferences are gone.
    for overrides <- [
          %{selected_locale: "en", has_locale_gap: 0},
          %{selected_locale: "ko", has_locale_gap: 1},
          %{has_locale_gap: 1},
          %{selected_locale: "en", has_locale_gap: 1}
        ] do
      insert_events([
        event(
          project_id,
          inserted_at,
          Map.merge(%{browser_language: "ja", served_locale: "en"}, overrides)
        )
      ])
    end

    assert %{pageviews: 4, locale_gap_visits: 3, top_browser_language: "ja"} =
             Queries.summary(project_id, since, until)

    opts = [since: since, until: until]

    assert Queries.browser_languages(project_id, ["ja", "en", "ko"], opts) == [
             %{
               browser_language: "ja",
               served_locale: "en",
               has_locale_gap: 1,
               visits: 3,
               is_served: true
             },
             %{
               browser_language: "ja",
               served_locale: "en",
               has_locale_gap: 0,
               visits: 1,
               is_served: true
             }
           ]

    assert [%{browser_language: "ja", visitors: 3}] =
             Queries.localization_priority(project_id, ["ja", "en", "ko"], opts)
  end

  test "traffic granularity follows the selected period" do
    start = datetime("2026-01-01T00:00:00Z")

    assert Queries.traffic_granularity(start, DateTime.add(start, 24, :hour)) == :hour
    assert Queries.traffic_granularity(start, DateTime.add(start, 30, :day)) == :day
    assert Queries.traffic_granularity(start, DateTime.add(start, 365, :day)) == :month
  end

  defp insert_events(rows) do
    opts = Event.buffer_opts()
    types = Enum.zip(opts.fields, opts.types) ++ [inserted_at: :datetime]
    IngestRepo.insert_all("analytics_events", rows, types: types)
  end

  defp event(project_id, inserted_at, overrides) do
    Map.merge(
      %{
        id: Uniq.UUID.uuid7(),
        project_id: project_id,
        visitor_id: 1,
        session_id: Ecto.UUID.generate(),
        name: "pageview",
        hostname: "example.com",
        pathname: "/",
        referrer: "",
        referrer_source: "",
        country_code: "US",
        browser_language: "en",
        served_locale: "",
        has_locale_gap: 0,
        device: "desktop",
        browser: "chrome",
        os: "macos",
        screen_width: 1_440,
        timezone: "Europe/Berlin",
        inserted_at: inserted_at
      },
      overrides
    )
  end

  defp datetime(value) do
    {:ok, datetime, 0} = DateTime.from_iso8601(value)
    datetime
  end
end
