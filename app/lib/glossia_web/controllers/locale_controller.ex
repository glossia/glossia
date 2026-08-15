defmodule GlossiaWeb.LocaleController do
  @moduledoc """
  Handles an explicit language choice made from the marketing site.

  The choice is remembered in a long-lived cookie, and — for signed-in people —
  written to their account, because a language they picked deliberately is
  their preference everywhere, dashboard included.

  Writing the account is what makes this a state-changing GET, so it only
  happens for a request the browser tells us came from our own pages. A link or
  an `<img>` on someone else's site can still set the cookie, which is a
  device-local preference the visitor can undo, but it cannot rewrite an
  account.
  """

  use GlossiaWeb, :controller

  alias Glossia.Accounts
  alias Glossia.I18n
  alias GlossiaWeb.Plugs.Locale

  def update(conn, %{"locale" => segment} = params) do
    case I18n.from_segment(segment) do
      nil ->
        conn
        |> put_status(:not_found)
        |> put_view(GlossiaWeb.ErrorHTML)
        |> render(:"404")

      locale ->
        conn
        |> maybe_update_user(locale)
        |> put_resp_cookie(Locale.cookie(), locale,
          max_age: Locale.cookie_max_age(),
          same_site: "Lax",
          http_only: true,
          secure: conn.scheme == :https
        )
        |> redirect(to: localized_return(locale, return_path(params)))
    end
  end

  # Only the marketing site has translated URLs. Coming from anywhere else —
  # the sign-up page, an invitation — the cookie and the account preference are
  # what carry the choice, so the visitor returns to the very same page.
  defp localized_return(locale, %URI{} = return_to) do
    localized = I18n.localize_path(locale, URI.to_string(return_to))

    # The prefixed path only counts as a translation of this page when it
    # dispatches to the same controller action. Catch-all routes would happily
    # match "/es/signup" and 404 later otherwise.
    if same_action?(return_to.path, URI.parse(localized).path) do
      localized
    else
      URI.to_string(return_to)
    end
  end

  defp same_action?(path, localized) do
    case {route_action(path), route_action(localized)} do
      {nil, _localized} -> false
      {action, action} -> true
      {_action, _other} -> false
    end
  end

  defp route_action(path) do
    case Phoenix.Router.route_info(GlossiaWeb.Router, "GET", path, "") do
      %{plug: plug, plug_opts: plug_opts} -> {plug, plug_opts}
      :error -> nil
    end
  end

  defp maybe_update_user(conn, locale) do
    user = conn.assigns[:current_user]

    if user && same_origin?(conn) do
      case Accounts.update_user_locale(user, locale) do
        {:ok, updated_user} -> assign(conn, :current_user, updated_user)
        {:error, _changeset} -> conn
      end
    else
      conn
    end
  end

  # Browsers label where a request came from. Browsers too old for that label
  # are held to the referrer instead; a request that claims neither only gets
  # the cookie.
  defp same_origin?(conn) do
    case get_req_header(conn, "sec-fetch-site") do
      [site] -> site in ["same-origin", "same-site", "none"]
      _missing -> same_origin_referer?(conn)
    end
  end

  defp same_origin_referer?(conn) do
    with [referer] <- get_req_header(conn, "referer"),
         %URI{host: host} when is_binary(host) <- URI.parse(referer) do
      host == URI.parse(GlossiaWeb.Endpoint.url()).host
    else
      _no_referer -> false
    end
  end

  # Only same-site paths are accepted so the switcher cannot be turned into an
  # open redirect: anything carrying a scheme or a host is dropped. The locale
  # already in the path goes too, since the visitor is on their way to another
  # translation of the same page.
  defp return_path(%{"return_to" => return_to}) when is_binary(return_to) do
    case URI.parse(return_to) do
      %URI{scheme: nil, host: nil, path: "/" <> _rest} = uri ->
        if safe_local_url?(return_to) do
          uri
          |> URI.to_string()
          |> I18n.split_path()
          |> elem(1)
          |> URI.parse()
        else
          %URI{path: "/"}
        end

      _off_site ->
        %URI{path: "/"}
    end
  end

  defp return_path(_params), do: %URI{path: "/"}

  # `redirect/2` raises on these rather than returning an error, and a raise on
  # a public GET route is a 500 anyone can trigger. They are the same sequences
  # a browser could read as leaving the site, so the answer is the home page.
  defp safe_local_url?(url), do: not String.contains?(url, ["\\", "/%09", "/\t"])
end
