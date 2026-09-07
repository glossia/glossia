defmodule GlossiaWeb.Plugs.MarketingLocale do
  @moduledoc """
  Locale behaviour that is specific to the public marketing site.

  Two things happen here that must not happen anywhere else:

    * an unprefixed URL redirects once to the visitor's language, so someone
      landing on `/blog` with a Spanish browser reads `/es/blog`. The redirect
      is skipped for crawlers (they must see the URL they asked for) and for
      anyone who picked a language explicitly, whose cookie then wins forever.

    * every page advertises its translations through `hreflang` alternates,
      with the unprefixed English URL as `x-default`.
  """

  import Plug.Conn

  alias Glossia.I18n

  @crawler_markers ~w(
    bot crawler spider slurp facebookexternalhit embedly quora
    pinterest bitlybot skypeuripreview nuzzel discordbot google-inspectiontool
    vkshare w3c_validator whatsapp telegrambot applebot chatgpt claudebot perplexity
  )

  def init(opts), do: opts

  def call(conn, _opts) do
    {locale, path} = I18n.split_path(conn.request_path)
    preferred = GlossiaWeb.Plugs.Locale.preferred_locale(conn)
    base_url = URI.parse(GlossiaWeb.Endpoint.url())

    conn =
      conn
      |> assign(:locale_alternates, alternates(base_url, path))
      |> assign(:canonical_url, absolute_url(base_url, I18n.localize_path(locale, path)))
      |> vary_on_negotiation()

    if redirect?(conn, path, preferred) do
      conn
      |> Phoenix.Controller.redirect(to: redirect_path(conn, path, preferred))
      |> halt()
    else
      conn
    end
  end

  defp redirect?(conn, path, preferred) do
    # A prefixed URL is an explicit request for that language: never bounce it.
    is_nil(conn.assigns[:url_locale]) and
      conn.method == "GET" and
      preferred != I18n.default_locale() and
      html_request?(conn, path) and
      not crawler?(conn)
  end

  defp redirect_path(conn, path, preferred) do
    query = if conn.query_string == "", do: nil, else: conn.query_string

    %URI{path: path, query: query}
    |> URI.to_string()
    |> then(&I18n.localize_path(preferred, &1))
  end

  # An unprefixed URL answers differently depending on the browser's language
  # and on the visitor's stored choice, so a shared cache must not serve one
  # visitor's redirect to the next one.
  defp vary_on_negotiation(%{assigns: %{url_locale: _locale}} = conn), do: conn

  defp vary_on_negotiation(conn) do
    put_resp_header(conn, "vary", "accept-language, cookie")
  end

  defp alternates(base_url, path) do
    translations =
      Enum.map(I18n.locales(), fn locale ->
        %{hreflang: locale, url: absolute_url(base_url, I18n.localize_path(locale, path))}
      end)

    translations ++ [%{hreflang: "x-default", url: absolute_url(base_url, path)}]
  end

  defp absolute_url(base_url, path), do: base_url |> URI.merge(path) |> URI.to_string()

  defp html_request?(conn, path) do
    not (String.ends_with?(path, ".xml") or String.ends_with?(path, ".json")) and
      conn |> get_req_header("accept") |> List.first("") |> String.contains?("text/html")
  end

  defp crawler?(conn) do
    user_agent =
      conn
      |> get_req_header("user-agent")
      |> List.first("")
      |> String.downcase()

    Enum.any?(@crawler_markers, &String.contains?(user_agent, &1))
  end
end
