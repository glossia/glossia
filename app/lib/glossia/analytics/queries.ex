defmodule Glossia.Analytics.Queries do
  @moduledoc """
  Read-side queries over the `analytics_events` ClickHouse table.

  All queries scope by `project_id` (a string) and bound the time window to
  `since` / `until`. Callers in the dashboard pass the project's target
  languages so the localization-gap calculations stay consistent with what
  the ingestion path computed.
  """

  import Ecto.Query

  alias Glossia.IngestRepo

  @doc """
  Top-of-dashboard summary: total pageviews, unique visitors, top country,
  top browser language, and the share of visits with a localization gap.
  """
  def summary(project_id, since \\ default_since(), until \\ DateTime.utc_now()) do
    since_dt = DateTime.truncate(since, :second)
    until_dt = DateTime.truncate(until, :second)

    project_id_str = to_string(project_id)

    base_query = fn window_start, window_end ->
      from(e in "analytics_events",
        where:
          e.project_id == ^project_id_str and
            e.inserted_at >= ^window_start and
            e.inserted_at < ^window_end
      )
    end

    base =
      base_query.(since_dt, until_dt)
      |> select([e], %{
        pageviews: count(e.id),
        unique_visitors: fragment("uniqExact(?)", e.visitor_id),
        locale_gap_visits: fragment("countIf(? = 1)", e.has_locale_gap)
      })

    base
    |> IngestRepo.one()
    |> case do
      nil ->
        empty_summary()

      row ->
        Map.merge(row, %{
          top_country: top_value(project_id, :country_code, since_dt, until_dt),
          top_browser_language: top_value(project_id, :browser_language, since_dt, until_dt)
        })
    end
  end

  # `topK(1)` cannot appear inside another aggregate function in ClickHouse
  # (`ILLEGAL_AGGREGATION`), so we compute the most-common value for the
  # window with a separate, single-column aggregate.
  defp top_value(project_id, column, since_dt, until_dt) do
    query =
      from(e in "analytics_events",
        where:
          e.project_id == ^to_string(project_id) and
            e.inserted_at >= ^since_dt and
            e.inserted_at < ^until_dt and
            field(e, ^column) != "",
        group_by: field(e, ^column),
        order_by: [desc: count(e.id)],
        limit: 1,
        select: field(e, ^column)
      )

    case IngestRepo.all(query) do
      [value | _] -> value || ""
      [] -> ""
    end
  end

  @doc """
  Pages by pageview count, descending. `limit` defaults to 10.
  """
  def top_pages(project_id, opts \\ []) do
    limit = Keyword.get(opts, :limit, 10)
    since = Keyword.get(opts, :since, default_since())
    until = Keyword.get(opts, :until, DateTime.utc_now())

    from(e in "analytics_events",
      where:
        e.project_id == ^to_string(project_id) and
          e.inserted_at >= ^DateTime.truncate(since, :second) and
          e.inserted_at < ^DateTime.truncate(until, :second) and
          e.name == "pageview",
      group_by: e.pathname,
      order_by: [desc: count(e.id)],
      limit: ^limit,
      select: %{pathname: e.pathname, pageviews: count(e.id)}
    )
    |> IngestRepo.all()
  end

  @doc """
  Visitors by country, descending. Empty-string countries (could not be
  geolocated) are reported as `Unknown` in the UI.
  """
  def top_countries(project_id, opts \\ []) do
    limit = Keyword.get(opts, :limit, 10)
    since = Keyword.get(opts, :since, default_since())
    until = Keyword.get(opts, :until, DateTime.utc_now())

    from(e in "analytics_events",
      where:
        e.project_id == ^to_string(project_id) and
          e.inserted_at >= ^DateTime.truncate(since, :second) and
          e.inserted_at < ^DateTime.truncate(until, :second),
      group_by: e.country_code,
      order_by: [desc: count(e.id)],
      limit: ^limit,
      select: %{country_code: e.country_code, visits: count(e.id)}
    )
    |> IngestRepo.all()
  end

  @doc """
  Browser languages by visit count, with the localization gap flagged. Used
  by the dashboard to show which languages the project's audience speaks
  vs. which ones the project serves.
  """
  def browser_languages(project_id, target_languages, opts \\ []) do
    limit = Keyword.get(opts, :limit, 20)
    since = Keyword.get(opts, :since, default_since())
    until = Keyword.get(opts, :until, DateTime.utc_now())

    served = Enum.map(target_languages || [], &String.downcase/1)

    from(e in "analytics_events",
      where:
        e.project_id == ^to_string(project_id) and
          e.inserted_at >= ^DateTime.truncate(since, :second) and
          e.inserted_at < ^DateTime.truncate(until, :second) and
          e.browser_language != "",
      group_by: [e.browser_language, e.has_locale_gap, e.served_locale],
      order_by: [desc: count(e.id)],
      limit: ^limit,
      select: %{
        browser_language: e.browser_language,
        served_locale: e.served_locale,
        has_locale_gap: e.has_locale_gap,
        visits: count(e.id)
      }
    )
    |> IngestRepo.all()
    |> Enum.map(fn row ->
      Map.put(row, :is_served, row.browser_language in served)
    end)
  end

  @doc """
  The visit-count time series bucketed by hour. Used by the sparkline /
  trend section of the dashboard.
  """
  def hourly_traffic(project_id, opts \\ []) do
    since = Keyword.get(opts, :since, default_since())
    until = Keyword.get(opts, :until, DateTime.utc_now())

    from(e in "analytics_events",
      where:
        e.project_id == ^to_string(project_id) and
          e.inserted_at >= ^DateTime.truncate(since, :second) and
          e.inserted_at < ^DateTime.truncate(until, :second),
      group_by: fragment("toStartOfHour(?)", e.inserted_at),
      order_by: [asc: fragment("toStartOfHour(?)", e.inserted_at)],
      select: %{
        bucket: fragment("toStartOfHour(?)", e.inserted_at),
        pageviews: count(e.id),
        unique_visitors: fragment("uniqExact(?)", e.visitor_id)
      }
    )
    |> IngestRepo.all()
  end

  @doc """
  Where to translate next. Joins visit counts with EF EPI English tolerance
  to produce a per-(country, language) priority score:

      priority = visitors * (1 - english_score)

  Only visits with a locale gap (`has_locale_gap = 1`) count — visitors who
  are happy with the languages the project already serves are not a
  localization opportunity. Returns the top `limit` rows, descending by
  priority. `target_languages` is currently unused at the SQL level but is
  accepted so the caller can pass the project's `setup_target_languages`
  for symmetry with the other queries.
  """
  def localization_priority(project_id, target_languages \\ [], opts \\ []) do
    limit = Keyword.get(opts, :limit, 20)
    since = Keyword.get(opts, :since, default_since())
    until = Keyword.get(opts, :until, DateTime.utc_now())

    rows =
      from(e in "analytics_events",
        where:
          e.project_id == ^to_string(project_id) and
            e.inserted_at >= ^DateTime.truncate(since, :second) and
            e.inserted_at < ^DateTime.truncate(until, :second) and
            e.has_locale_gap == 1 and
            e.country_code != "" and
            e.browser_language != "",
        group_by: [e.country_code, e.browser_language],
        order_by: [desc: count(e.id)],
        limit: ^limit,
        select: %{
          country_code: e.country_code,
          browser_language: e.browser_language,
          visitors: count(e.id)
        }
      )
      |> IngestRepo.all()

    # `target_languages` is passed for symmetry with the other queries and
    # so callers do not have to branch when passing project settings; the
    # SQL already filters on `has_locale_gap = 1`, which is the source of
    # truth for "the project does not serve this language".
    _ = target_languages

    rows
    |> Enum.map(fn row ->
      score = Glossia.Analytics.EnglishProficiency.english_score(row.country_code)

      %{
        country_code: row.country_code,
        country_name: Glossia.Analytics.EnglishProficiency.name(row.country_code),
        browser_language: row.browser_language,
        visitors: row.visitors,
        english_score: score,
        priority_score: Float.round(row.visitors * (1.0 - score), 2),
        centroid: Glossia.Analytics.EnglishProficiency.centroid(row.country_code)
      }
    end)
    |> Enum.sort_by(& &1.priority_score, :desc)
  end

  defp default_since do
    DateTime.utc_now() |> DateTime.add(-30 * 24 * 60 * 60, :second)
  end

  defp empty_summary do
    %{
      pageviews: 0,
      unique_visitors: 0,
      top_country: "",
      top_browser_language: "",
      locale_gap_visits: 0
    }
  end
end
