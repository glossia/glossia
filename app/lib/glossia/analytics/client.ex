defmodule Glossia.Analytics.Client do
  @moduledoc """
  Pure enrichment of the raw payload sent by the `@glossia/web` SDK.

  Every function here is deterministic and side-effect free, which keeps the
  localization logic trivial to unit test and reason about. No network access,
  no storage.
  """

  # ---------------------------------------------------------------------------
  # URL
  # ---------------------------------------------------------------------------

  def parse_url(nil), do: %{hostname: "", pathname: "/"}

  def parse_url(url) when is_binary(url) do
    case URI.parse(url) do
      %URI{host: host, path: path} when is_binary(host) and host != "" ->
        %{hostname: String.downcase(host), pathname: normalize_path(path)}

      _ ->
        %{hostname: "", pathname: "/"}
    end
  end

  defp normalize_path(nil), do: "/"
  defp normalize_path(""), do: "/"
  defp normalize_path(path), do: path

  # ---------------------------------------------------------------------------
  # Referrer
  # ---------------------------------------------------------------------------

  def parse_referrer(nil), do: %{referrer: "", referrer_source: ""}
  def parse_referrer(""), do: %{referrer: "", referrer_source: ""}

  def parse_referrer(referrer) when is_binary(referrer) do
    case URI.parse(referrer) do
      %URI{host: host} when is_binary(host) and host != "" ->
        %{referrer: referrer, referrer_source: host |> String.downcase() |> strip_prefix()}

      _ ->
        %{referrer: "", referrer_source: ""}
    end
  end

  defp strip_prefix(host) do
    host
    |> String.trim_leading("www.")
    |> String.trim_leading("m.")
  end

  # ---------------------------------------------------------------------------
  # User-Agent
  # ---------------------------------------------------------------------------

  def parse_user_agent(nil), do: %{device: "unknown", browser: "unknown", os: "unknown"}

  def parse_user_agent(user_agent) when is_binary(user_agent) do
    ua = String.downcase(user_agent)

    %{
      device: detect_device(ua),
      browser: detect_browser(ua),
      os: detect_os(ua)
    }
  end

  defp detect_device(ua) do
    cond do
      String.contains?(ua, "bot") or String.contains?(ua, "crawl") or
          String.contains?(ua, "spider") ->
        "bot"

      String.contains?(ua, "ipad") or String.contains?(ua, "tablet") ->
        "tablet"

      String.contains?(ua, "mobi") or String.contains?(ua, "iphone") or
          String.contains?(ua, "android") ->
        "mobile"

      true ->
        "desktop"
    end
  end

  # Edge/Firefox/Opera must be matched before Chrome, since their UAs also
  # contain "chrome/".
  defp detect_browser(ua) do
    cond do
      String.contains?(ua, "edg/") -> "edge"
      String.contains?(ua, "opr/") or String.contains?(ua, "opera") -> "opera"
      String.contains?(ua, "firefox/") -> "firefox"
      String.contains?(ua, "chrome/") -> "chrome"
      String.contains?(ua, "safari/") -> "safari"
      true -> "unknown"
    end
  end

  # iOS must be matched before macOS: iPhone UAs include "Mac OS X".
  defp detect_os(ua) do
    cond do
      String.contains?(ua, "windows") ->
        "windows"

      String.contains?(ua, "iphone") or String.contains?(ua, "ipad") or
          String.contains?(ua, " ios") ->
        "ios"

      String.contains?(ua, "mac os") or String.contains?(ua, "macintosh") ->
        "macos"

      String.contains?(ua, "android") ->
        "android"

      String.contains?(ua, "linux") ->
        "linux"

      true ->
        "unknown"
    end
  end

  # ---------------------------------------------------------------------------
  # Languages & localization gap
  # ---------------------------------------------------------------------------

  @doc """
  Parses a browser-languages string such as `navigator.languages.join(",")` or
  an `Accept-Language` header into an ordered list of normalized Glossia
  locales, most preferred first.
  """
  def parse_languages(nil), do: []
  def parse_languages(""), do: []

  def parse_languages(languages) when is_binary(languages) do
    languages
    |> String.split(",")
    |> Enum.map(&parse_language_token/1)
    |> Enum.reject(&is_nil/1)
  end

  defp parse_language_token(token) do
    [tag | _] = String.split(token, ";")
    tag = tag |> String.trim() |> String.downcase()

    cond do
      tag == "" -> nil
      String.contains?(tag, "*") -> nil
      true -> normalize_locale(tag)
    end
  end

  # Collapse common browser tags onto Glossia's canonical locale identifiers so
  # they line up with `setup_target_languages`.
  @locale_mappings %{
    "zh" => "zh-Hans",
    "zh-cn" => "zh-Hans",
    "zh-sg" => "zh-Hans",
    "zh-hans" => "zh-Hans",
    "zh-tw" => "zh-Hant",
    "zh-hk" => "zh-Hant",
    "zh-hant" => "zh-Hant",
    "pt" => "pt-BR",
    "pt-br" => "pt-BR",
    "pt-pt" => "pt-PT",
    "no" => "nb",
    "nb" => "nb",
    "tl" => "fil"
  }

  defp normalize_locale(tag), do: Map.get(@locale_mappings, tag) || capitalize_region(tag)

  defp capitalize_region(tag) do
    case String.split(tag, "-") do
      [lang] -> lang
      [lang, region | _] -> Enum.join([lang, String.upcase(region)], "-")
    end
  end

  @doc """
  Returns `{browser_language, served_locale, has_locale_gap}`.

    * `browser_language` is the visitor's most preferred normalized locale.
    * `served_locale` is the first of the project's `target_locales` that
      matches any preferred locale (by exact or base-language match), or `""`
      when nothing matches.
    * `has_locale_gap` is `1` only when the visitor stated a preference that the
      project does not serve. Unknown preference (empty list) is `0` so the
      headline gap metric is never inflated by missing data.
  """
  def localize(preferred, target_locales)
      when is_list(preferred) and is_list(target_locales) do
    browser_language = List.first(preferred) || ""

    served_locale =
      Enum.find_value(target_locales, fn target ->
        if matches?(target, preferred), do: target
      end) || ""

    has_locale_gap =
      if preferred != [] and served_locale == "", do: 1, else: 0

    {browser_language, served_locale, has_locale_gap}
  end

  defp matches?(target, preferred) do
    target_base = base_language(target)

    Enum.any?(preferred, fn locale ->
      locale == target or base_language(locale) == target_base
    end)
  end

  defp base_language(locale), do: locale |> String.split("-") |> List.first()
end
