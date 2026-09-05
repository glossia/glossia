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
  Visitors by country, descending. Visits that could not be geolocated are
  omitted rather than presented as a country.
  """
  def top_countries(project_id, opts \\ []) do
    limit = Keyword.get(opts, :limit, 10)
    since = Keyword.get(opts, :since, default_since())
    until = Keyword.get(opts, :until, DateTime.utc_now())

    from(e in "analytics_events",
      where:
        e.project_id == ^to_string(project_id) and
          e.inserted_at >= ^DateTime.truncate(since, :second) and
          e.inserted_at < ^DateTime.truncate(until, :second) and
          e.country_code != "",
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
  The visit-count time series, bucketed to suit the requested period.

  Periods up to 48 hours use hourly buckets, periods up to 90 days use daily
  buckets, and longer periods use monthly buckets. Empty buckets are included
  so the chart preserves the selected period instead of compressing quiet
  stretches of time.
  """
  def traffic(project_id, opts \\ []) do
    since = Keyword.get(opts, :since, default_since())
    until = Keyword.get(opts, :until, DateTime.utc_now())
    granularity = traffic_granularity(since, until)

    points =
      project_id
      |> traffic_query(since, until, granularity)
      |> IngestRepo.all()
      |> fill_traffic_buckets(since, until, granularity)

    %{granularity: Atom.to_string(granularity), points: points}
  end

  @doc """
  Chooses the chart bucket size for a selected analytics period.
  """
  def traffic_granularity(since, until) do
    duration = max(DateTime.diff(until, since, :second), 0)

    cond do
      duration <= 48 * 60 * 60 -> :hour
      duration <= 90 * 24 * 60 * 60 -> :day
      true -> :month
    end
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

  defp traffic_query(project_id, since, until, :hour) do
    from(e in "analytics_events",
      where:
        e.project_id == ^to_string(project_id) and
          e.inserted_at >= ^DateTime.truncate(since, :second) and
          e.inserted_at < ^DateTime.truncate(until, :second),
      group_by: fragment("toStartOfHour(toTimeZone(?, 'UTC'))", e.inserted_at),
      order_by: [asc: fragment("toStartOfHour(toTimeZone(?, 'UTC'))", e.inserted_at)],
      select: %{
        bucket:
          fragment(
            "formatDateTime(toStartOfHour(toTimeZone(?, 'UTC')), '%FT%TZ', 'UTC')",
            e.inserted_at
          ),
        pageviews: count(e.id),
        unique_visitors: fragment("uniqExact(?)", e.visitor_id)
      }
    )
  end

  defp traffic_query(project_id, since, until, :day) do
    from(e in "analytics_events",
      where:
        e.project_id == ^to_string(project_id) and
          e.inserted_at >= ^DateTime.truncate(since, :second) and
          e.inserted_at < ^DateTime.truncate(until, :second),
      group_by: fragment("toStartOfDay(toTimeZone(?, 'UTC'))", e.inserted_at),
      order_by: [asc: fragment("toStartOfDay(toTimeZone(?, 'UTC'))", e.inserted_at)],
      select: %{
        bucket:
          fragment(
            "formatDateTime(toStartOfDay(toTimeZone(?, 'UTC')), '%FT%TZ', 'UTC')",
            e.inserted_at
          ),
        pageviews: count(e.id),
        unique_visitors: fragment("uniqExact(?)", e.visitor_id)
      }
    )
  end

  defp traffic_query(project_id, since, until, :month) do
    from(e in "analytics_events",
      where:
        e.project_id == ^to_string(project_id) and
          e.inserted_at >= ^DateTime.truncate(since, :second) and
          e.inserted_at < ^DateTime.truncate(until, :second),
      group_by: fragment("toStartOfMonth(toTimeZone(?, 'UTC'))", e.inserted_at),
      order_by: [asc: fragment("toStartOfMonth(toTimeZone(?, 'UTC'))", e.inserted_at)],
      select: %{
        bucket:
          fragment(
            "formatDateTime(toStartOfMonth(toTimeZone(?, 'UTC')), '%FT%TZ', 'UTC')",
            e.inserted_at
          ),
        pageviews: count(e.id),
        unique_visitors: fragment("uniqExact(?)", e.visitor_id)
      }
    )
  end

  defp fill_traffic_buckets([], _since, _until, _granularity), do: []

  defp fill_traffic_buckets(rows, since, until, granularity) do
    counts =
      Map.new(rows, fn row ->
        {bucket_iso8601(row.bucket), Map.drop(row, [:bucket])}
      end)

    since
    |> start_of_bucket(granularity)
    |> Stream.iterate(&next_bucket(&1, granularity))
    |> Enum.take_while(&(DateTime.compare(&1, until) == :lt))
    |> Enum.map(fn bucket ->
      bucket = DateTime.to_iso8601(bucket)

      Map.merge(
        %{bucket: bucket, pageviews: 0, unique_visitors: 0},
        Map.get(counts, bucket, %{})
      )
    end)
  end

  defp start_of_bucket(datetime, :hour) do
    %{datetime | minute: 0, second: 0, microsecond: {0, 0}}
  end

  defp start_of_bucket(datetime, :day) do
    datetime
    |> DateTime.to_date()
    |> DateTime.new!(~T[00:00:00], "Etc/UTC")
  end

  defp start_of_bucket(datetime, :month) do
    date = DateTime.to_date(datetime)
    DateTime.new!(Date.new!(date.year, date.month, 1), ~T[00:00:00], "Etc/UTC")
  end

  defp next_bucket(datetime, :hour), do: DateTime.add(datetime, 1, :hour)
  defp next_bucket(datetime, :day), do: DateTime.add(datetime, 1, :day)

  defp next_bucket(datetime, :month) do
    date = DateTime.to_date(datetime)

    next_date =
      if date.month == 12,
        do: Date.new!(date.year + 1, 1, 1),
        else: Date.new!(date.year, date.month + 1, 1)

    DateTime.new!(next_date, ~T[00:00:00], "Etc/UTC")
  end

  defp bucket_iso8601(%DateTime{} = datetime), do: DateTime.to_iso8601(datetime)
  defp bucket_iso8601(bucket) when is_binary(bucket), do: bucket

  defp bucket_iso8601(%Date{} = date) do
    date
    |> DateTime.new!(~T[00:00:00], "Etc/UTC")
    |> DateTime.to_iso8601()
  end

  defp bucket_iso8601(%NaiveDateTime{} = datetime) do
    datetime
    |> DateTime.from_naive!("Etc/UTC")
    |> DateTime.to_iso8601()
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
