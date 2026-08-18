defmodule Glossia.Quality.Checks do
  @moduledoc false

  alias Glossia.Quality
  alias Glossia.Quality.DOM
  alias Glossia.Quality.PageAddress

  def run(run, pages) do
    configuration = run.configuration
    source_locale = configuration["source_locale"]
    locale_origins = configuration["locale_origins"] || %{}

    pages
    |> Enum.each(fn page ->
      check_load(run, page)

      if map_size(locale_origins) > 1 do
        check_document_locale(run, page)
        check_alternate_navigation(run, page, locale_origins)
      end
    end)

    if map_size(locale_origins) > 1, do: check_source_leakage(run, pages, source_locale)
    :ok
  end

  defp check_load(_run, %{load_error: nil}), do: :ok

  defp check_load(run, page) do
    Quality.record_finding(
      run,
      page,
      %{
        check: "page_load",
        category: "navigation",
        severity: "high",
        title: "Page could not be loaded",
        description: "The headless browser could not load #{page.requested_url}.",
        locale: page.locale,
        logical_path: page.logical_path,
        metadata: %{"error" => page.load_error || "unknown"}
      },
      %{"requested_url" => page.requested_url, "error" => page.load_error || "unknown"}
    )
  end

  defp check_document_locale(_run, %{load_error: error}) when not is_nil(error), do: :ok

  defp check_document_locale(run, page) do
    if locale_matches?(page.document_locale, page.locale) do
      :ok
    else
      actual = page.document_locale || "missing"

      Quality.record_finding(
        run,
        page,
        %{
          check: "document_locale",
          category: "language",
          severity: "medium",
          title: "Page language does not match the selected locale",
          description: "The #{page.locale} page declares #{actual} as its document language.",
          locale: page.locale,
          logical_path: page.logical_path,
          target_text: actual,
          metadata: %{"expected_locale" => page.locale, "document_locale" => actual}
        },
        %{"requested_url" => page.requested_url}
      )
    end
  end

  defp check_alternate_navigation(_run, %{load_error: error}, _origins) when not is_nil(error),
    do: :ok

  defp check_alternate_navigation(run, page, origins) do
    origins
    |> Map.keys()
    |> Enum.reject(&(&1 == page.locale))
    |> Enum.each(fn target_locale ->
      expected = PageAddress.build(Map.fetch!(origins, target_locale), page.logical_path)
      actual = alternate_for(page.alternate_links, target_locale)

      cond do
        is_nil(actual) ->
          Quality.record_finding(
            run,
            page,
            %{
              check: "alternate_navigation_missing",
              category: "navigation",
              severity: "low",
              title: "Cross-language navigation is missing",
              description:
                "The #{page.locale} page does not expose an alternate link for #{target_locale}.",
              locale: page.locale,
              logical_path: page.logical_path,
              metadata: %{"target_locale" => target_locale, "expected_url" => expected}
            },
            %{"requested_url" => page.requested_url, "alternate_links" => page.alternate_links}
          )

        equivalent_address?(actual, expected) ->
          :ok

        true ->
          Quality.record_finding(
            run,
            page,
            %{
              check: "alternate_navigation_wrong_destination",
              category: "navigation",
              severity: "high",
              title: "Language switch points to a different page",
              description:
                "Switching from #{page.locale} to #{target_locale} points to #{actual} instead of the equivalent page.",
              locale: page.locale,
              logical_path: page.logical_path,
              target_text: actual,
              metadata: %{"target_locale" => target_locale, "expected_url" => expected}
            },
            %{"requested_url" => page.requested_url, "actual_url" => actual}
          )
      end
    end)
  end

  defp check_source_leakage(run, pages, source_locale) do
    pages
    |> Enum.group_by(& &1.logical_path)
    |> Enum.each(fn {_path, path_pages} ->
      source_page = Enum.find(path_pages, &(&1.locale == source_locale and is_nil(&1.load_error)))

      if source_page do
        source_blocks = source_page.visible_text |> DOM.text_blocks() |> MapSet.new()

        path_pages
        |> Enum.reject(&(&1.locale == source_locale or not is_nil(&1.load_error)))
        |> Enum.each(&record_leaked_blocks(run, source_blocks, &1))
      end
    end)
  end

  defp record_leaked_blocks(run, source_blocks, page) do
    page.visible_text
    |> DOM.text_blocks()
    |> Enum.filter(&MapSet.member?(source_blocks, &1))
    |> Enum.filter(&meaningful_source_text?/1)
    |> Enum.take(5)
    |> Enum.each(fn text ->
      Quality.record_finding(
        run,
        page,
        %{
          check: "possible_untranslated_content",
          category: "language",
          severity: "medium",
          title: "Possible untranslated content",
          description:
            "This #{page.locale} page contains the same substantial text as the source page.",
          locale: page.locale,
          logical_path: page.logical_path,
          source_text: text,
          target_text: text,
          metadata: %{}
        },
        %{"requested_url" => page.requested_url, "text" => text}
      )
    end)
  end

  defp meaningful_source_text?(text) do
    if byte_size(text) <= 500 do
      letters = Regex.scan(~r/\p{L}/u, text) |> length()
      words = Regex.scan(~r/[\p{L}\p{N}]+/u, text) |> length()
      letters >= 18 and words >= 3
    else
      false
    end
  end

  defp alternate_for(links, locale) do
    candidates = locale_candidates(locale)

    Enum.find_value(candidates, &Map.get(links, &1)) ||
      Enum.find_value(candidates, fn candidate ->
        Enum.find_value(links, fn {link_locale, address} ->
          normalized = normalize_locale(link_locale)
          if String.starts_with?(normalized, candidate <> "-"), do: address
        end)
      end)
  end

  defp locale_matches?(nil, _expected), do: false

  defp locale_matches?(actual, expected) do
    actual = normalize_locale(actual)
    expected = normalize_locale(expected)
    actual == expected or String.starts_with?(actual, expected <> "-")
  end

  defp normalize_locale(locale), do: locale |> String.replace("_", "-") |> String.downcase()

  defp locale_candidates(locale) do
    normalized = normalize_locale(locale)
    [normalized, normalized |> String.split("-", parts: 2) |> List.first()] |> Enum.uniq()
  end

  defp equivalent_address?(left, right) do
    normalize_address(left) == normalize_address(right)
  end

  defp normalize_address(address) do
    uri = URI.parse(address)
    path = if uri.path in [nil, ""], do: "/", else: uri.path
    URI.to_string(%URI{uri | path: path, fragment: nil})
  end
end
