defmodule GlossiaWeb.LiveHooks.PublicPageChallenge do
  @moduledoc ~S"""
  LiveView on_mount hook paired with
  `GlossiaWeb.Plugs.PublicPageChallengePlug`. Runs at the connected
  mount so a client that opens a LiveSocket directly (bypassing the
  dead-render Plug pipeline) still gets challenged before any dashboard
  query fires.

  The freshness check reads the same session key the plug sets, so a
  visitor who solved the challenge on a sibling page in the same
  browser continues without re-solving.

  Wire this hook FIRST in the on_mount list of every live_session that
  serves anonymous readers of a public account or project, so no
  downstream hook (account load, write-check) does expensive work
  before the visitor has proven human.
  """
  alias Phoenix.LiveView
  alias Glossia.Cloudflare.Turnstile.PublicPage
  alias GlossiaWeb.Plugs.PublicPageChallengePlug

  def on_mount(:default, _params, session, socket) do
    cond do
      not PublicPage.required?() ->
        {:cont, socket}

      signed_in?(session) ->
        {:cont, socket}

      PublicPageChallengePlug.verified_within_freshness?(session) ->
        # Fresh at mount time is not fresh forever: patch navigation
        # (`push_patch`) does not remount the LiveView, so the wall
        # clock can drift past the freshness window inside the same
        # LiveSocket. `handle_params` fires on every intra-session
        # navigation, so re-running the freshness check there catches
        # the stale case a scraper would otherwise ride out. The
        # session map is closed over so the hook re-reads the same
        # stored timestamp — LiveView will not hand us a fresh session
        # mid-connection.
        {:cont, maybe_attach_expiry_hook(socket, session)}

      true ->
        {:halt, redirect_to_challenge(socket, nil)}
    end
  end

  defp check_expiry(session, uri, socket) do
    if PublicPageChallengePlug.verified_within_freshness?(session) do
      {:cont, socket}
    else
      {:halt, redirect_to_challenge(socket, uri)}
    end
  end

  # `attach_hook/4` requires the LiveView to be router-mounted (the
  # macro sets `socket.router`). Bare `%Socket{}`s in unit tests do not
  # carry one; skip the attach in that case rather than blowing up. In
  # production the router always sets it, so the intra-session expiry
  # re-check keeps running.
  defp maybe_attach_expiry_hook(socket, session) do
    if socket.router do
      hook = fn _params, uri, s -> check_expiry(session, uri, s) end
      LiveView.attach_hook(socket, :public_page_challenge_expiry, :handle_params, hook)
    else
      socket
    end
  end

  # Preserves the URI the visitor was trying to reach when the mount (or
  # a navigation) was rejected. The controller reads `return_to` from
  # query string first, falling back to the session key the Plug
  # populated on the dead-render path, so both entry vectors land the
  # visitor back where they were after solving the challenge.
  defp redirect_to_challenge(socket, uri) do
    to =
      case return_to_from(uri) do
        nil ->
          PublicPageChallengePlug.challenge_path()

        path ->
          PublicPageChallengePlug.challenge_path() <> "?return_to=" <> URI.encode_www_form(path)
      end

    LiveView.redirect(socket, to: to)
  end

  defp return_to_from(nil), do: nil

  defp return_to_from(uri) when is_binary(uri) do
    parsed = URI.parse(uri)

    case parsed.path do
      nil ->
        nil

      path ->
        case parsed.query do
          nil -> path
          "" -> path
          qs -> path <> "?" <> qs
        end
    end
  end

  # Glossia stores the signed-in user's id directly on the session; the
  # plug uses the same predicate for the dead-render path.
  defp signed_in?(session) do
    case session["user_id"] do
      id when not is_nil(id) -> true
      _ -> false
    end
  end
end
