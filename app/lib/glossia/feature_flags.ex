defmodule Glossia.FeatureFlags do
  @moduledoc """
  Server-wide feature flag helpers, layered on top of FunWithFlags.

  The FunWithFlags helpers are used directly elsewhere in the app; this
  module exists to encode composite policies that are not a straight
  boolean read (e.g. an environment toggle that a kill switch can flip
  off even when the toggle is on).
  """

  @doc """
  Whether Cloudflare Turnstile is enforced on the sign-up surface.

  Turnstile is opt-in per environment (`GLOSSIA_TURNSTILE_ENABLED`).
  When the kill-switch flag `:turnstile_kill_switch` is on, the gate
  is bypassed globally without a redeploy — this is the break-glass
  for a Cloudflare-side incident, not the primary toggle.
  """
  def turnstile_enabled? do
    Glossia.Cloudflare.Turnstile.env_enabled?() and
      not FunWithFlags.enabled?(:turnstile_kill_switch)
  end
end
