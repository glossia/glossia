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
 */

export type GlossiaConfig = {
  /** Project public key (pk_...). Required. */
  key: string;
  /** Collect endpoint. Defaults to the origin of the SDK script + "/v1/collect". */
  endpoint?: string;
  /** Send a pageview on init and on client-side navigation. Default: true. */
  autoPageviews?: boolean;
};

type EventPayload = {
  k: string;
  n: string;
  u: string;
  r: string;
  l: string;
  tz: string;
  sw: number;
  sid: string;
};

const SESSION_KEY = "__glossia_sid";

let endpoint = "/v1/collect";
let projectKey: string | null = null;
let sessionId: string | null = null;

function detectEndpoint(): string {
  if (typeof document === "undefined") return "/v1/collect";
  const script = document.currentScript as HTMLScriptElement | null;
  if (script && script.src) {
    try {
      return new URL(script.src, document.baseURI).origin + "/v1/collect";
    } catch {
      return "/v1/collect";
    }
  }
  return "/v1/collect";
}

function browserLanguages(): string {
  const nav = typeof navigator !== "undefined" ? navigator : undefined;
  const langs =
    (nav && nav.languages) ||
    (nav && nav.language ? [nav.language] : []) ||
    [];
  return langs.join(",");
}

function timezone(): string {
  try {
    return Intl.DateTimeFormat().resolvedOptions().timeZone || "";
  } catch {
    return "";
  }
}

function screenWidth(): number {
  try {
    return (typeof screen !== "undefined" && screen.width) || 0;
  } catch {
    return 0;
  }
}

function uuid(): string {
  const c = typeof crypto !== "undefined" ? crypto : undefined;
  if (c && typeof c.randomUUID === "function") return c.randomUUID();

  return "xxxxxxxxxxxx4xxxyxxxxxxxxxxxxxxx".replace(/[xy]/g, (ch) => {
    const r = (Math.random() * 16) | 0;
    const v = ch === "x" ? r : (r & 0x3) | 0x8;
    return v.toString(16);
  });
}

function readOrCreateSessionId(): string {
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

function send(payload: EventPayload): void {
  if (!projectKey) return;
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

function build(name: string): EventPayload {
  return {
    k: projectKey || "",
    n: name,
    u: typeof location !== "undefined" ? location.href : "",
    r: typeof document !== "undefined" ? document.referrer : "",
    l: browserLanguages(),
    tz: timezone(),
    sw: screenWidth(),
    sid: readOrCreateSessionId(),
  };
}

/** Record a custom event (e.g. `glossia("track", "signup")`). */
export function track(name: string): void {
  send(build(name));
}

/** Record a pageview. Called automatically when `autoPageviews` is on. */
export function pageview(): void {
  send(build("pageview"));
}

/** Initialize the SDK. Safe to call once. */
export function init(config: GlossiaConfig): void {
  if (!config.key) return;
  projectKey = config.key;
  endpoint = config.endpoint || detectEndpoint();
  readOrCreateSessionId();

  if (config.autoPageviews !== false) {
    pageview();
    hookHistory();
  }
}

function hookHistory(): void {
  if (typeof history === "undefined") return;

  const push = history.pushState;
  const replace = history.replaceState;
  const fire = () => setTimeout(pageview, 0);

  history.pushState = function (this: History, ...args: unknown[]) {
    const ret = push.apply(this, args as Parameters<typeof push>);
    fire();
    return ret;
  };
  history.replaceState = function (this: History, ...args: unknown[]) {
    const ret = replace.apply(this, args as Parameters<typeof replace>);
    fire();
    return ret;
  };
  window.addEventListener("popstate", fire);
}

// Auto-initialize from a classic script tag:
//   <script defer src="https://cdn.glossia.ai/web.js" data-key="pk_..."></script>
if (typeof document !== "undefined") {
  const script = document.currentScript as HTMLScriptElement | null;
  const key = script?.getAttribute("data-key");
  if (key) {
    init({ key, endpoint: script?.getAttribute("data-endpoint") || undefined });
  }
}

export default { init, track, pageview };
