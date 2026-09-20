defmodule GlossiaWeb.PublicPageChallengeHTML do
  @moduledoc ~S"""
  Renders the Turnstile challenge page shown at
  `GET /turnstile-challenge`. Kept intentionally self-contained: no
  LiveView, no dashboard chrome. The page loads Cloudflare's `api.js`,
  renders a widget bound to the `public_page_challenge` action, and
  posts the token back to the controller inside a CSRF-protected form.

  The inline script mirrors the shape of Glossia's signup Turnstile
  integration (`assets/js/turnstile.js`), reused here without the phx
  hook since this page runs outside the LiveView bundle.
  """
  use GlossiaWeb, :html

  def render("show.html", assigns) do
    ~H"""
    <!DOCTYPE html>
    <html lang="en">
      <head>
        <meta charset="utf-8" />
        <meta name="viewport" content="width=device-width, initial-scale=1" />
        <meta name="robots" content="noindex, nofollow" />
        <title>{gettext("Verify you're human")}</title>
        <style>
          :root {
            color-scheme: light dark;
            --bg: #f5f5f7;
            --card: #ffffff;
            --fg: #1d1d1f;
            --muted: #4b4b4f;
            --accent: #4338ca;
            --error: #b3261e;
            --disabled: #a0a0a0;
          }
          :root[data-theme="dark"] {
            --bg: #0f172a;
            --card: #1e293b;
            --fg: #f1f5f9;
            --muted: #94a3b8;
            --accent: #a5b4fc;
            --error: #f87171;
            --disabled: #475569;
          }
          html, body { margin: 0; padding: 0; background: var(--bg); color: var(--fg); }
          body {
            font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif;
            display: flex;
            align-items: center;
            justify-content: center;
            min-height: 100vh;
            padding: 1rem;
            box-sizing: border-box;
          }
          .card {
            background: var(--card);
            border-radius: 16px;
            padding: 32px 28px;
            width: min(420px, 92vw);
            box-shadow: 0 12px 32px rgba(0, 0, 0, 0.06);
            text-align: center;
          }
          .card h1 {
            font-size: 20px;
            margin: 0 0 8px 0;
          }
          .card p {
            margin: 0 0 20px 0;
            color: var(--muted);
            font-size: 14px;
          }
          .widget {
            display: flex;
            justify-content: center;
            margin: 16px 0;
          }
          .error {
            color: var(--error);
            font-size: 13px;
            margin-top: 12px;
          }
          .fallback {
            font-size: 12px;
            color: var(--muted);
            margin-top: 16px;
          }
          button {
            font: inherit;
            border: none;
            background: var(--accent);
            color: #ffffff;
            padding: 10px 18px;
            border-radius: 999px;
            cursor: pointer;
          }
          button[disabled] {
            background: var(--disabled);
            cursor: not-allowed;
          }
        </style>
        <script>
          (function () {
            var dark =
              window.matchMedia && window.matchMedia("(prefers-color-scheme: dark)").matches;
            document.documentElement.style.setProperty("color-scheme", dark ? "dark" : "light");
            document.documentElement.setAttribute("data-theme", dark ? "dark" : "light");
          })();
        </script>
      </head>
      <body>
        <div class="card">
          <h1>{gettext("Just a quick check")}</h1>
          <p>
            {gettext(
              "Public dashboards are protected against automated scraping. Confirm you're human to continue."
            )}
          </p>

          <form method="post" action={@verify_path} id="public-page-challenge-form">
            <input type="hidden" name="_csrf_token" value={get_csrf_token()} />
            <input type="hidden" name="return_to" value={@return_to || "/"} />
            <input type="hidden" name="cf-turnstile-response" id="turnstile-response" value="" />

            <div
              :if={@turnstile_required? and is_binary(@turnstile_site_key)}
              id="turnstile-widget"
              class="widget"
              data-sitekey={@turnstile_site_key}
              data-action={@expected_action}
            >
            </div>

            <div
              :if={not @turnstile_required? or not is_binary(@turnstile_site_key)}
              class="fallback"
            >
              {gettext("Turnstile is unavailable. Please try again shortly.")}
            </div>

            <p :if={@error} class="error" role="alert">{@error}</p>

            <button type="submit" id="public-page-challenge-submit" disabled>
              {gettext("Continue")}
            </button>
          </form>
        </div>

        <script :if={@turnstile_required? and is_binary(@turnstile_site_key)}>
          (function () {
            var API_URL = "https://challenges.cloudflare.com/turnstile/v0/api.js?render=explicit";
            var ONLOAD_CALLBACK = "__glossiaPublicPageChallengeOnLoad";
            var container = document.getElementById("turnstile-widget");
            var responseInput = document.getElementById("turnstile-response");
            var submitButton = document.getElementById("public-page-challenge-submit");
            var form = document.getElementById("public-page-challenge-form");

            function setSubmitEnabled(enabled) {
              if (submitButton) submitButton.disabled = !enabled;
            }

            window[ONLOAD_CALLBACK] = function () {
              if (!window.turnstile || !container) return;
              try {
                window.turnstile.render(container, {
                  sitekey: container.dataset.sitekey,
                  action: container.dataset.action,
                  "response-field": false,
                  callback: function (token) {
                    if (responseInput) responseInput.value = token;
                    setSubmitEnabled(true);
                    if (form && typeof form.requestSubmit === "function") {
                      form.requestSubmit();
                    } else if (form) {
                      form.submit();
                    }
                  },
                  "expired-callback": function () {
                    if (responseInput) responseInput.value = "";
                    setSubmitEnabled(false);
                  },
                  "error-callback": function () {
                    if (responseInput) responseInput.value = "";
                    setSubmitEnabled(false);
                  },
                  "timeout-callback": function () {
                    if (responseInput) responseInput.value = "";
                    setSubmitEnabled(false);
                  }
                });
              } catch (_e) {
                setSubmitEnabled(false);
              }
            };

            var script = document.createElement("script");
            script.src = API_URL + "&onload=" + ONLOAD_CALLBACK;
            script.async = true;
            script.defer = true;
            script.onerror = function () { setSubmitEnabled(false); };
            document.head.appendChild(script);
          })();
        </script>
      </body>
    </html>
    """
  end
end
