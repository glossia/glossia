defmodule Glossia.I18n do
  @moduledoc """
  Single source of truth for the locales Glossia's own surfaces are available in.

  A locale here is the canonical Gettext locale (the directory name under
  `priv/gettext` and `priv/i18n`). English is the source language: it is the
  fallback for every missing translation and the only locale served without a
  prefix in marketing URLs.

  URLs use a lowercased segment for each locale (`/pt-br`, `/zh-hans`) so links
  stay case-insensitive, while `hreflang` and Gettext keep the canonical casing.
  """

  @default_locale "en"

  @locales [
    %{
      locale: "en",
      segment: "en",
      native_name: "English",
      english_name: "English"
    },
    %{
      locale: "de",
      segment: "de",
      native_name: "Deutsch",
      english_name: "German"
    },
    %{
      locale: "es",
      segment: "es",
      native_name: "Español",
      english_name: "Spanish"
    },
    %{
      locale: "fr",
      segment: "fr",
      native_name: "Français",
      english_name: "French"
    },
    %{
      locale: "ja",
      segment: "ja",
      native_name: "日本語",
      english_name: "Japanese"
    },
    %{
      locale: "ko",
      segment: "ko",
      native_name: "한국어",
      english_name: "Korean"
    },
    %{
      locale: "pt-BR",
      segment: "pt-br",
      native_name: "Português (Brasil)",
      english_name: "Portuguese (Brazil)"
    },
    %{
      locale: "zh-Hans",
      segment: "zh-hans",
      native_name: "简体中文",
      english_name: "Chinese (Simplified)"
    }
  ]

  # Aliases accept the language tags browsers actually send, lowercased and
  # without the region when the region does not change the translation.
  @aliases %{
    "zh" => "zh-Hans",
    "zh-cn" => "zh-Hans",
    "zh-sg" => "zh-Hans",
    "zh-hans" => "zh-Hans",
    "pt" => "pt-BR",
    "pt-br" => "pt-BR"
  }

  # Every locale name CLDR knows, in URL-segment form: 766 language, script and
  # region combinations, maintained upstream rather than by us. `ex_cldr` is a
  # compile-time dependency, so this is a literal list by the time it ships.
  @cldr_segments Cldr.all_locale_names()
                 |> Enum.map(&(&1 |> Atom.to_string() |> String.downcase()))
                 |> Enum.sort()

  # CLDR drops a handful of ISO 639-1 languages, mostly small or historic ones
  # it has no data for. They are still languages someone could ask us to
  # translate into, so they are reserved too.
  @iso_639_1_gaps ~w(
    ae av ay bh bi ch cr fj ho hz ik kg kj kr kv
    li mh na ng oj sm tl tw ty
  )

  def default_locale, do: @default_locale

  def locales, do: Enum.map(@locales, & &1.locale)

  @doc """
  Every language identifier that must never become an account handle, because
  it either is or could become the prefix of a translated marketing URL.

  Our own segments are in here explicitly: CLDR files Brazilian Portuguese
  under plain `pt`, so `pt-br` — a URL we serve today — would otherwise be
  missing from a list derived from CLDR alone.
  """
  def reservable_segments do
    (@cldr_segments ++ @iso_639_1_gaps ++ Enum.map(locales(), &segment/1))
    |> Enum.uniq()
    |> Enum.sort()
  end

  def translated_locales, do: Enum.reject(locales(), &(&1 == @default_locale))

  def supported?(locale), do: locale in locales()

  def metadata(locale), do: Enum.find(@locales, &(&1.locale == locale))

  def native_name(locale) do
    case metadata(locale) do
      nil -> locale
      %{native_name: name} -> name
    end
  end

  def english_name(locale) do
    case metadata(locale) do
      nil -> locale
      %{english_name: name} -> name
    end
  end

  @doc """
  The URL segment for a locale, e.g. `"pt-br"` for `"pt-BR"`.
  """
  def segment(locale) do
    case metadata(locale) do
      nil -> locale
      %{segment: segment} -> segment
    end
  end

  @doc """
  The canonical locale for a URL segment, or `nil` when the segment is not a
  locale we serve.
  """
  def from_segment(segment) when is_binary(segment) do
    downcased = String.downcase(segment)

    case Enum.find(@locales, &(&1.segment == downcased)) do
      nil -> nil
      %{locale: locale} -> locale
    end
  end

  def from_segment(_segment), do: nil

  @doc """
  Normalizes a language tag (`"es-ES"`, `"zh-CN"`, `"PT-br"`) to a canonical
  locale we serve, or `nil` when we do not serve it.
  """
  def normalize(nil), do: nil

  def normalize(tag) when is_binary(tag) do
    downcased = tag |> String.trim() |> String.downcase()

    cond do
      alias_locale = Map.get(@aliases, downcased) ->
        alias_locale

      locale = exact_match(downcased) ->
        locale

      true ->
        downcased |> String.split("-") |> List.first() |> exact_match()
    end
  end

  @doc """
  Prefixes a path built with `~p` with the locale segment. English is served
  without a prefix, so it returns the path untouched.

      iex> Glossia.I18n.localize_path("es", "/blog")
      "/es/blog"
      iex> Glossia.I18n.localize_path("en", "/blog")
      "/blog"
  """
  def localize_path(locale, path)

  def localize_path(@default_locale, path), do: path

  def localize_path(locale, path) do
    uri = URI.parse(path)

    if supported?(locale) and absolute_path?(uri) do
      URI.to_string(%{uri | path: "/#{segment(locale)}#{normalize_root(uri.path)}"})
    else
      path
    end
  end

  @doc """
  Splits the locale segment off a request path, returning the locale (English
  when the path carries no prefix) and the unprefixed path.

      iex> Glossia.I18n.split_path("/es/blog")
      {"es", "/blog"}
      iex> Glossia.I18n.split_path("/blog")
      {"en", "/blog"}
  """
  def split_path(path) do
    uri = URI.parse(path)

    with true <- absolute_path?(uri),
         ["/", segment | rest] <- Path.split(uri.path),
         locale when not is_nil(locale) <- from_segment(segment) do
      {locale, URI.to_string(%{uri | path: Path.join(["/" | rest])})}
    else
      _no_prefix -> {@default_locale, path}
    end
  end

  defp absolute_path?(%URI{scheme: nil, host: nil, path: "/" <> _rest}), do: true
  defp absolute_path?(_uri), do: false

  # "/" is the one path that must not keep its slash once prefixed: the Spanish
  # home page is "/es", not "/es/".
  defp normalize_root("/"), do: ""
  defp normalize_root(path), do: path

  @doc """
  Picks the best locale out of an `Accept-Language` header value, honouring the
  quality values browsers send. Returns `nil` when nothing matches.
  """
  def from_accept_language(nil), do: nil

  def from_accept_language(header) when is_binary(header) do
    header
    |> String.split(",")
    |> Enum.map(&parse_language_range/1)
    |> Enum.reject(&is_nil/1)
    |> Enum.sort_by(fn {_tag, quality} -> quality end, :desc)
    |> Enum.find_value(fn {tag, _quality} -> normalize(tag) end)
  end

  defp exact_match(downcased) do
    case Enum.find(@locales, &(String.downcase(&1.locale) == downcased)) do
      nil -> nil
      %{locale: locale} -> locale
    end
  end

  defp parse_language_range(range) do
    case range |> String.trim() |> String.split(";") do
      [""] ->
        nil

      [tag] ->
        {tag, 1.0}

      [tag | params] ->
        {tag, quality(params)}
    end
  end

  defp quality(params) do
    params
    |> Enum.find_value(fn param ->
      case param |> String.trim() |> String.split("=") do
        ["q", value] -> Float.parse(value)
        _other -> nil
      end
    end)
    |> case do
      {quality, _rest} -> quality
      nil -> 1.0
    end
  end
end
