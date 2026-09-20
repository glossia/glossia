defmodule Glossia.Cloudflare.Turnstile.PublicPage do
  @moduledoc """
  Widget-specific configuration and enforcement gate for the public-page
  Turnstile challenge (the interstitial shown to anonymous visitors
  before they can browse a public account or project).

  The public-page widget is a *separate* Cloudflare Turnstile widget
  from the signup widget, provisioned by its own
  `CloudflareTurnstileWidget` custom resource, with its own site key
  and secret. Keeping the two widgets independent means telemetry,
  secret rotation, kill-switch flips, and a per-widget incident stay
  scoped to their own surface.

  `required?/0` folds the compile-time enable flag (env-driven) with a
  FunWithFlags kill switch, so an incident can turn the challenge off
  in production without a deploy.
  """

  alias Glossia.Cloudflare.Turnstile

  @kill_switch_flag :public_page_challenge_kill_switch
  @default_freshness_seconds 3_600

  @doc """
  True when the public-page challenge should enforce.

  Enforces when:

    * `Application.get_env(:glossia, __MODULE__)[:enabled?]` is true
      (compile-time / env override).
    * AND the `:public_page_challenge_kill_switch` FunWithFlags flag is
      NOT enabled (operator has not pulled the kill switch).
  """
  def required? do
    config(:enabled?, false) and not kill_switch_pulled?()
  end

  @doc "Public site key rendered into the widget markup."
  def site_key, do: config(:site_key)

  @doc "Secret key used for the siteverify round-trip."
  def secret_key, do: config(:secret_key)

  @doc """
  Freshness window, in seconds, that a successful verification lets a
  visitor browse without re-solving. Defaults to one hour.
  """
  def freshness_seconds do
    config(:freshness_seconds, @default_freshness_seconds)
  end

  @doc """
  Verify a Turnstile response token against Cloudflare's siteverify with
  the public-page widget's secret. Delegates to
  `Glossia.Cloudflare.Turnstile.verify/2` so the parsing and hostname
  binding logic stays shared. `expected_action` binds the token to a
  specific widget so a token solved for signup cannot be replayed here.
  """
  def verify(token, opts \\ []) do
    opts =
      opts
      |> Keyword.put_new(:secret_key, secret_key())
      |> Keyword.put_new(:required?, required?())

    Turnstile.verify(token, opts)
  end

  defp kill_switch_pulled? do
    # `FunWithFlags.enabled?/1` returns false when the flag has never been
    # set, which is the safe default: an operator explicitly enables the
    # flag to pull the kill switch. A missing FunWithFlags supervisor
    # would raise, but the app boot wires it under
    # `Glossia.Application.parent_children/0`.
    FunWithFlags.enabled?(@kill_switch_flag)
  end

  defp config(key, default \\ nil) do
    :glossia
    |> Application.get_env(__MODULE__, [])
    |> Keyword.get(key, default)
  end
end
