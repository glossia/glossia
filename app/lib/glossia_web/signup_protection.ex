defmodule GlossiaWeb.SignupProtection do
  @moduledoc """
  Combined per-session rate limit + Turnstile siteverify for the
  account-creation surface. Returns `:ok` when the caller is allowed to
  proceed, and a tagged error the controller maps to a flash message
  otherwise.

  Turnstile is opt-in per environment. When it is off (dev, kill switch,
  etc.) this module short-circuits to `:ok` and does not hit the
  rate-limit bucket either — the widget being absent means there is
  nothing to check against and hitting the bucket would rate-limit
  legitimate manual QA.
  """

  alias Glossia.Cloudflare.Turnstile
  alias GlossiaWeb.RateLimit.Registration

  @doc """
  Verify a signup submission.

    * `session_token` — the request's CSRF token, used as the
      rate-limit bucket key. `nil` or empty string returns
      `{:error, :missing_session}` before touching Turnstile.
    * `params` — the submitted form params, from which we pull
      `"cf-turnstile-response"` (the widget's hidden input name).
    * `expected_action` — the widget's `action` attribute, so a token
      solved for one form cannot be replayed against another.
  """
  def verify(session_token, params, expected_action) do
    if Turnstile.required?() do
      with {:allow, _count} <- Registration.hit(session_token),
           :ok <-
             Turnstile.verify(Map.get(params, "cf-turnstile-response"),
               expected_action: expected_action
             ) do
        :ok
      else
        {:deny, _retry_after_ms} -> {:error, :rate_limited}
        {:error, :missing_session} -> {:error, :missing_session}
        # Operator-visible: a rollout wired the widget without a secret
        # key. Surfaced distinctly so the failure mode gets its own
        # flash + doesn't blend into legitimate-looking bot rejections.
        {:error, :misconfigured} -> {:error, :misconfigured}
        {:error, _reason} -> {:error, :turnstile_failed}
      end
    else
      :ok
    end
  end
end
