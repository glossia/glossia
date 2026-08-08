/**
 * @glossia/web — cookieless, privacy-friendly web analytics for Glossia.
 *
 * The SDK collects only what is needed to surface localization opportunities:
 * the page URL, referrer, browser languages, timezone, and screen width. It
 * stores nothing on the device (no cookies, no fingerprinting). A per-tab
 * session id (kept in `sessionStorage`, cleared on close) is sent so a single
 * visit can group pageviews, but no identifier persists across sessions.
 *
 * The server derives the unique visitor (a daily-rotated hash of IP + UA) and
 * the country from GeoIP, so neither the IP nor the User-Agent is ever stored.
 *
 * @module @glossia/web
 */

/**
 * @typedef {object} GlossiaConfig
 * @property {string} [domain] - Site domain that identifies the project,
 *   e.g. "example.com". Defaults to `window.location.hostname` when omitted.
 * @property {string} [endpoint] - Collect endpoint. Defaults to the origin
 *   of the SDK script + "/v1/collect".
 * @property {boolean} [autoPageviews=true] - Send a pageview on init and on
 *   client-side navigation.
 */

/**
 * @typedef {object} EventPayload
 * @property {string} d
 * @property {string} n
 * @property {string} u
 * @property {string} r
 * @property {string} l
 * @property {string} tz
 * @property {number} sw
 * @property {string} sid
 */

const SESSION_KEY = "__glossia_sid";

let endpoint = "/v1/collect";
let siteDomain = null;
let sessionId = null;

function detectEndpoint() {
  if (typeof document === "undefined") return "/v1/collect";
  const script = document.currentScript;
  if (script && script.src) {
    try {
      return new URL(script.src, document.baseURI).origin + "/v1/collect";
    } catch {
      return "/v1/collect";
    }
  }
  return "/v1/collect";
}

function browserLanguages() {
  const nav = typeof navigator !== "undefined" ? navigator : undefined;
  const langs =
    (nav && nav.languages) ||
    (nav && nav.language ? [nav.language] : []) ||
    [];
  return langs.join(",");
}

function timezone() {
  try {
    return Intl.DateTimeFormat().resolvedOptions().timeZone || "";
  } catch {
    return "";
  }
}

function screenWidth() {
  try {
    return (typeof screen !== "undefined" && screen.width) || 0;
  } catch {
    return 0;
  }
}

function uuid() {
  const c = typeof crypto !== "undefined" ? crypto : undefined;
  if (c && typeof c.randomUUID === "function") return c.randomUUID();

  return "xxxxxxxxxxxx4xxxyxxxxxxxxxxxxxxx".replace(/[xy]/g, (ch) => {
    const r = (Math.random() * 16) | 0;
    const v = ch === "x" ? r : (r & 0x3) | 0x8;
    return v.toString(16);
  });
}

function readOrCreateSessionId() {
  if (sessionId) return sessionId;

  // sessionStorage is scoped to the tab and cleared on close: enough to group a
  // single visit without persisting a cross-session identifier.
  try {
    const store = window.sessionStorage;
    sessionId = store.getItem(SESSION_KEY);
    if (!sessionId) {
      sessionId = uuid();
      store.setItem(SESSION_KEY, sessionId);
    }
    return sessionId;
  } catch {
    sessionId = sessionId || uuid();
    return sessionId;
  }
}

function send(payload) {
  if (!siteDomain) return;
  const body = JSON.stringify(payload);

  // Prefer sendBeacon for reliability during page unload; fall back to fetch.
  if (typeof navigator !== "undefined" && typeof navigator.sendBeacon === "function") {
    try {
      const blob = new Blob([body], { type: "application/json" });
      if (navigator.sendBeacon(endpoint, blob)) return;
    } catch {
      /* fall through to fetch */
    }
  }

  try {
    void fetch(endpoint, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body,
      keepalive: true,
      credentials: "omit",
      mode: "cors",
    });
  } catch {
    /* Analytics must never break the host page. */
  }
}

function build(name) {
  return {
    d: siteDomain || "",
    n: name,
    u: typeof location !== "undefined" ? location.href : "",
    r: typeof document !== "undefined" ? document.referrer : "",
    l: browserLanguages(),
    tz: timezone(),
    sw: screenWidth(),
    sid: readOrCreateSessionId(),
  };
}

/**
 * Record a custom event (e.g. `glossia("track", "signup")`).
 * @param {string} name
 */
export function track(name) {
  send(build(name));
}

/**
 * Record a pageview. Called automatically when `autoPageviews` is on.
 */
export function pageview() {
  send(build("pageview"));
}

/**
 * Initialize the SDK. Safe to call once.
 * @param {GlossiaConfig} [config]
 */
export function init(config = {}) {
  // Default the site domain to the current hostname so the common case is
  // just `glossia.init()`. Explicit override exists for setups where the
  // SDK runs on a different origin than the one registered in Glossia
  // (e.g. a staging environment reporting to the same project).
  const domain =
    config.domain ?? (typeof location !== "undefined" ? location.hostname : "");
  if (!domain) return;
  siteDomain = domain;
  endpoint = config.endpoint || detectEndpoint();
  readOrCreateSessionId();

  if (config.autoPageviews !== false) {
    pageview();
    hookHistory();
  }
}

function hookHistory() {
  if (typeof history === "undefined") return;

  const push = history.pushState;
  const replace = history.replaceState;
  const fire = () => setTimeout(pageview, 0);

  history.pushState = function (...args) {
    const ret = push.apply(this, args);
    fire();
    return ret;
  };
  history.replaceState = function (...args) {
    const ret = replace.apply(this, args);
    fire();
    return ret;
  };
  window.addEventListener("popstate", fire);
}

// Auto-initialize from a classic script tag:
//   <script defer src="https://cdn.glossia.ai/web.js" data-domain="example.com"></script>
//
// `data-domain` is optional; if omitted, the SDK falls back to the current
// hostname. `data-endpoint` is also optional and only needed when self-hosting.
if (typeof document !== "undefined") {
  const script = document.currentScript;
  if (script) {
    const domain = script.getAttribute("data-domain") || undefined;
    const endpoint = script.getAttribute("data-endpoint") || undefined;
    if (domain || endpoint) {
      init({ domain, endpoint });
    } else {
      init();
    }
  }
}

export default { init, track, pageview };
