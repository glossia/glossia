defmodule GlossiaWeb.PublicPageChallengeHTML do
  @moduledoc ~S"""
  Renders the Turnstile challenge page shown at
  `GET /turnstile-challenge`. Kept intentionally self-contained: no
  LiveView, no dashboard chrome. The page links the app's token
  stylesheets (`styles.css`, `noora.css`) so its colors, typography, and
  borders track the rest of the design system — a rebrand of
  `--color-primary` / `--color-text` propagates here without a template
  edit. It loads Cloudflare's `api.js`, renders a widget bound to the
  `public_page_challenge` action, and posts the token back to the
  controller inside a CSRF-protected form.

  The inline script mirrors the shape of Glossia's signup Turnstile
  integration, reused here without the phx hook since this page runs
  outside the LiveView bundle.
  """
  use GlossiaWeb, :html

  def render("show.html", assigns) do
    ~H"""
    <!DOCTYPE html>
    <html lang={assigns[:locale] || Glossia.I18n.default_locale()}>
      <head>
        <meta charset="utf-8" />
        <meta name="viewport" content="width=device-width, initial-scale=1" />
        <meta name="robots" content="noindex, nofollow" />
        <title>{gettext("Verify you're human")}</title>
        <link
          rel="stylesheet"
          href={
            Phoenix.VerifiedRoutes.static_path(
              GlossiaWeb.Endpoint,
              Application.get_env(:glossia, :asset_paths, %{})[:stylesheet] || "/assets/styles.css"
            )
          }
        />
        <link
          rel="stylesheet"
          href={
            Phoenix.VerifiedRoutes.static_path(
              GlossiaWeb.Endpoint,
              Application.get_env(:glossia, :asset_paths, %{})[:noora_stylesheet] ||
                "/assets/noora.css"
            )
          }
        />
        <style>
          html, body {
            margin: 0;
            padding: 0;
            background: var(--color-surface);
            color: var(--color-text);
          }
          body {
            font-family: var(--font-family-sans);
            display: flex;
            align-items: center;
            justify-content: center;
            min-height: 100vh;
            padding: var(--space-3, 1rem);
            box-sizing: border-box;
          }
          .card {
            background: var(--color-surface);
            border: 1px solid var(--color-border);
            border-radius: var(--radius-lg, 16px);
            padding: 2rem 1.75rem;
            width: min(420px, 92vw);
            text-align: center;
          }
          .card h1 {
            font-size: 1.25rem;
            margin: 0 0 0.5rem;
            color: var(--color-text);
          }
          .card p {
            margin: 0 0 1.25rem;
            color: var(--color-text-muted);
            font-size: 0.875rem;
          }
          .widget {
            display: flex;
            justify-content: center;
            margin: 1rem 0;
          }
          .error {
            color: var(--color-error);
            font-size: 0.8125rem;
            margin-top: 0.75rem;
          }
          .fallback {
            font-size: 0.75rem;
            color: var(--color-text-muted);
            margin-top: 1rem;
          }
          button {
            font: inherit;
            border: none;
            background: var(--color-primary);
            color: var(--color-text-on-accent, #ffffff);
            padding: 0.625rem 1.125rem;
            border-radius: 999px;
            cursor: pointer;
          }
          button:hover:not([disabled]) { background: var(--color-primary-hover); }
          button[disabled] {
            background: var(--color-border-strong);
            cursor: not-allowed;
          }
        </style>
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
