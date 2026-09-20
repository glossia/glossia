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

  Only the initial connected mount is gated. Intra-session navigation
  (`push_patch`) reuses the session captured at mount time, and LiveView
  will not hand us a fresh session mid-connection; re-running the
  freshness check on `handle_params` from a captured stale session was
  what the earlier design tried and it produced a real bug: if a sibling
  tab re-solved the challenge, the captured session in tab A would still
  read old, and the redirect target's own conn saw the fresh session and
  bounced the user back to `/` instead of the page they were trying to
  navigate to. Freshness is bounded at one hour by default, so the
  worst-case bypass is one session of one crawler for the freshness
  window — accepted because every cost-bearing dashboard action is
  guarded by write authorization anonymous visitors never satisfy.

  Wire this hook FIRST in the on_mount list of every live_session that
  serves anonymous readers of a public account or project, so no
  downstream hook does expensive work before the visitor has proven
  human.
  """
  use GlossiaWeb, :verified_routes

  alias Phoenix.LiveView
  alias Glossia.Cloudflare.Turnstile.PublicPage
  alias GlossiaWeb.Plugs.PublicPageChallengePlug

  def on_mount(:default, _params, session, socket) do
    cond do
      not PublicPage.required?() ->
        {:cont, socket}

      PublicPageChallengePlug.signed_in?(session) ->
        {:cont, socket}

      PublicPageChallengePlug.verified_within_freshness?(session) ->
        {:cont, socket}

      true ->
        {:halt, redirect_to_challenge(socket, nil)}
    end
  end

  # Preserves the URI the visitor was trying to reach when the mount was
  # rejected. The controller reads `return_to` from query string first,
  # falling back to the session key the Plug populated on the dead-render
  # path, so both entry vectors land the visitor back where they were
  # after solving the challenge. The URL is built with `~p` so a rename
  # of the challenge route surfaces at compile time.
  defp redirect_to_challenge(socket, uri) do
    to =
      case return_to_from(uri) do
        nil -> ~p"/turnstile-challenge"
        path -> ~p"/turnstile-challenge?return_to=#{path}"
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
end
