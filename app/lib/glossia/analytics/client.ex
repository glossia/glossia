defmodule Glossia.Analytics.Client do
  @moduledoc """
  Pure enrichment of the raw payload sent by the `@glossia/web` SDK.

  Every function here is deterministic and side-effect free, which keeps the
  localization logic trivial to unit test and reason about. No network access,
  no storage.
  """

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

  @doc """
  Classifies a User-Agent into device / browser / OS buckets using
  `UAInspector` (Matomo's continuously-updated device database), the same
  library Plausible relies on. The browser-name normalization and device-type
  buckets mirror Plausible's, so mobile variants collapse onto their base
  browser (e.g. "Chrome Mobile" -> "Chrome"). Returns `"unknown"` for any field
  the database can't resolve so downstream aggregation never breaks on missing
  data.
  """
  def parse_user_agent(nil), do: %{device: "unknown", browser: "unknown", os: "unknown"}

  def parse_user_agent(user_agent) when is_binary(user_agent) do
    case UAInspector.parse(user_agent) do
      %UAInspector.Result.Bot{} ->
        %{device: "bot", browser: "bot", os: "unknown"}

      %UAInspector.Result{client: client, device: device, os: os} ->
        %{
          device: device_bucket(device),
          browser: browser_name(client),
          os: os_name(os)
        }
    end
  end

  # Device-type buckets, following Plausible's grouping of UAInspector's
  # fine-grained types.
  @mobile_types ~w(smartphone feature\ phone portable\ media\ player phablet wearable camera)
  @tablet_types ~w(car\ browser tablet)
  @desktop_types ~w(tv console desktop)

  defp device_bucket(%UAInspector.Result.Device{type: type}) do
    cond do
      type in @mobile_types -> "mobile"
      type in @tablet_types -> "tablet"
      type in @desktop_types -> "desktop"
      true -> "unknown"
    end
  end

  defp device_bucket(_), do: "unknown"

  # Collapse mobile/branded browser variants onto their base browser name, as
  # Plausible does, so the dashboard doesn't split "Chrome" from "Chrome Mobile".
  defp browser_name(%UAInspector.Result.Client{name: name}) do
    case name do
      "Mobile Safari" -> "Safari"
      "Chrome Mobile" -> "Chrome"
      "Chrome Mobile iOS" -> "Chrome"
      "Firefox Mobile" -> "Firefox"
      "Firefox Mobile iOS" -> "Firefox"
      "Opera Mobile" -> "Opera"
      "Opera Mini" -> "Opera"
      "Opera Mini iOS" -> "Opera"
      "Yandex Browser Lite" -> "Yandex Browser"
      "Chrome Webview" -> "Mobile App"
      :unknown -> "unknown"
      name when is_binary(name) -> name
    end
  end

  defp browser_name(_), do: "unknown"

  defp os_name(%UAInspector.Result.OS{name: name}) when is_binary(name), do: name
  defp os_name(_), do: "unknown"

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
