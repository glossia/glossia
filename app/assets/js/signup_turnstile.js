// Cloudflare Turnstile bootstrap for the sign-up page. The page is
// controller-rendered (no LiveView) so we can't use a LiveView hook the
// way tuist/tuist#12868 does upstream; the shape below preserves the
// same load-order-safe + optimistic-submit behavior in vanilla JS.
//
// Design notes worth preserving verbatim from the upstream postmortem:
//
//  * `?onload=` callback pattern (never `turnstile.ready()`) — the
//    latter throws under `defer` and left the widget silently broken
//    for hours during the 2026-09-03 outage.
//  * Module-level singleton promise: only inject api.js once even if
//    this module runs twice (initial paint + phx:page-loading-stop).
//  * Optimistic submit: if the user clicks a provider button before
//    the token arrives, park the intent, show "Verifying...", and
//    re-fire the submit as soon as the callback lands.
//  * Fail-open UI: on api-load-failure the buttons stay clickable and
//    the status area explains what happened, rather than a permanently
//    disabled sign-up flow because Cloudflare's CDN blipped.

const API_URL = "https://challenges.cloudflare.com/turnstile/v0/api.js?render=explicit"
const API_LOAD_TIMEOUT_MS = 10000
const ONLOAD_CALLBACK_NAME = "__glossiaTurnstileOnLoad"

let apiPromise = null

function loadApi() {
  if (apiPromise) return apiPromise
  if (window.turnstile) {
    apiPromise = Promise.resolve(window.turnstile)
    return apiPromise
  }

  apiPromise = new Promise((resolve, reject) => {
    let timeoutHandle = null
    const cleanup = () => {
      if (timeoutHandle) window.clearTimeout(timeoutHandle)
      delete window[ONLOAD_CALLBACK_NAME]
    }

    window[ONLOAD_CALLBACK_NAME] = () => {
      cleanup()
      resolve(window.turnstile)
    }

    const script = document.createElement("script")
    script.src = `${API_URL}&onload=${ONLOAD_CALLBACK_NAME}`
    script.async = true
    script.defer = true
    script.onerror = () => {
      cleanup()
      apiPromise = null
      reject(new Error("turnstile-api-load-failed"))
    }

    timeoutHandle = window.setTimeout(() => {
      cleanup()
      apiPromise = null
      reject(new Error("turnstile-api-load-timeout"))
    }, API_LOAD_TIMEOUT_MS)

    document.head.appendChild(script)
  })

  return apiPromise
}

function setStatus(root, state, message) {
  const status = root.querySelector("[data-signup-turnstile-status]")
  if (!status) return
  root.dataset.state = state
  status.textContent = message || ""
}

function mirrorToken(token) {
  document.querySelectorAll("[data-turnstile-response-mirror]").forEach(input => {
    input.value = token
  })
}

function clearToken() {
  document.querySelectorAll("[data-turnstile-response-mirror]").forEach(input => {
    input.value = ""
  })
}

function ready(form) {
  if (form && typeof form.requestSubmit === "function") {
    form.requestSubmit()
  } else if (form) {
    form.submit()
  }
}

export default function initSignupTurnstile() {
  const root = document.querySelector("[data-signup-turnstile]")
  if (!root) return
  if (root.dataset.initialized === "true") return
  root.dataset.initialized = "true"

  const sitekey = root.dataset.sitekey
  const action = root.dataset.action || "signup"

  let widgetId = null
  let hasToken = false
  let pendingSubmitForm = null
  let apiFailed = false

  const forms = document.querySelectorAll("form[data-part='provider-form']")
  forms.forEach(form => {
    form.addEventListener("submit", event => {
      if (apiFailed) return
      if (hasToken) {
        // The token is single-use at Cloudflare; if OAuth bounces the
        // user back to /signup (provider cancel, session expiry, etc.)
        // the mirrored value would fail siteverify silently on the
        // next provider click. Consume it locally and re-solve.
        hasToken = false
        clearToken()
        if (widgetId !== null && window.turnstile) {
          try {
            window.turnstile.reset(widgetId)
          } catch (_error) {
            /* iframe already gone */
          }
        }
        return
      }
      event.preventDefault()
      pendingSubmitForm = form
      setStatus(
        root,
        "pending-submit",
        root.dataset.pendingLabel || "Verifying, one moment..."
      )
    })
  })

  setStatus(root, "pending", "")

  loadApi().then(
    turnstile => {
      try {
        widgetId = turnstile.render(root, {
          sitekey,
          action,
          "response-field": false,
          callback: token => {
            hasToken = true
            mirrorToken(token)
            setStatus(root, "ready", "")
            if (pendingSubmitForm) {
              const form = pendingSubmitForm
              pendingSubmitForm = null
              ready(form)
            }
          },
          "expired-callback": () => {
            hasToken = false
            clearToken()
            setStatus(root, "pending", "")
          },
          "error-callback": () => {
            hasToken = false
            clearToken()
            setStatus(
              root,
              "error",
              root.dataset.errorLabel ||
                "The sign-up challenge didn't complete. Please try again."
            )
          },
          "timeout-callback": () => {
            hasToken = false
            clearToken()
            setStatus(root, "error", root.dataset.errorLabel || "Challenge timed out. Please try again.")
          },
        })
      } catch (_error) {
        apiFailed = true
        setStatus(
          root,
          "unavailable",
          root.dataset.unavailableLabel ||
            "Sign-up challenge is unavailable. Try again in a moment."
        )
      }

      if (widgetId === undefined || widgetId === null) {
        apiFailed = true
        setStatus(
          root,
          "unavailable",
          root.dataset.unavailableLabel ||
            "Sign-up challenge is unavailable. Try again in a moment."
        )
      }
    },
    () => {
      apiFailed = true
      setStatus(
        root,
        "unavailable",
        root.dataset.unavailableLabel ||
          "Sign-up challenge is unavailable. Try again in a moment."
      )
    }
  )
}
