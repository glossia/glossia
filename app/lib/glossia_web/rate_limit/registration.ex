defmodule GlossiaWeb.RateLimit.Registration do
  @moduledoc """
  Per-CSRF-session rate limit for the account-creation surface.

  A single-use Turnstile token still has to be solved per attempt, so
  replay protection stays tight even at a comfortable per-session
  ceiling. The bucket is debited on every sign-up submit; a first-try
  user often burns two or three slots to typos alone (weak handle,
  taken email), so the ceiling is picked to keep those recoverable
  without shipping a per-error refund path.

  Keyed on `sha256(csrf_token)` so the raw session token never lands in
  Hammer's ETS table (or in any downstream log line).
  """

  @limit 10
  # 5-minute window; hitting the ceiling forces a several-minute cool-down
  # even for a real user who is fat-fingering things, which is a bearable
  # UX cost given how catastrophic a scripted sign-up flood would be.
  @scale_ms :timer.minutes(5)

  def hit(session_token) when is_binary(session_token) and session_token != "" do
    key = "registration:" <> hashed_key(session_token)
    Glossia.RateLimiter.hit(key, @scale_ms, @limit)
  end

  def hit(_session_token), do: {:error, :missing_session}

  defp hashed_key(session_token) do
    :sha256
    |> :crypto.hash(session_token)
    |> Base.url_encode64(padding: false)
  end
end
