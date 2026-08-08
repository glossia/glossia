import { describe, it, expect, afterEach, vi } from "vitest";

// The SDK caches `siteDomain`, `endpoint`, and `sessionId` at module scope and
// wraps `history.pushState` / `history.replaceState` on `init()`. Re-importing
// the module gives us a fresh module, but `window.history` is shared, so the
// wrappers would otherwise accumulate. We capture the originals once and
// restore them every time we load the SDK.
const originalPushState = window.history.pushState;
const originalReplaceState = window.history.replaceState;

async function loadFresh() {
  window.history.pushState = originalPushState;
  window.history.replaceState = originalReplaceState;
  vi.resetModules();
  return import("./index.js");
}

// --- DOM/network helpers ----------------------------------------------------
// Every helper below uses `vi.spyOn` or `vi.stubGlobal` so the original is
// restored automatically by `vi.restoreAllMocks()` / `vi.unstubAllGlobals()`
// in the shared `afterEach`. No test mutates a global without an undo path.

function makeFakeScript({ src, domain, endpoint } = {}) {
  const script = document.createElement("script");
  if (src !== undefined) script.setAttribute("src", src);
  if (domain !== undefined) script.setAttribute("data-domain", domain);
  if (endpoint !== undefined) script.setAttribute("data-endpoint", endpoint);
  return script;
}

function stubSendBeacon(returns = true) {
  return vi.spyOn(navigator, "sendBeacon").mockReturnValue(returns);
}

function stubFetch(impl) {
  return vi.stubGlobal(
    "fetch",
    impl ?? vi.fn().mockResolvedValue({ ok: true }),
  );
}

function stubLocation(url) {
  return vi
    .spyOn(window, "location", "get")
    .mockReturnValue(new URL(url));
}

function stubReferrer(value) {
  return vi.spyOn(document, "referrer", "get").mockReturnValue(value);
}

function stubCurrentScript(script) {
  return vi
    .spyOn(document, "currentScript", "get")
    .mockReturnValue(script);
}

// Each test that needs a sessionStorage gets a fresh in-memory map. The
// returned `map` is the underlying store so the test can assert on it
// directly; `mock` exposes call records on the individual methods.
function stubSessionStorage() {
  const map = new Map();
  const mock = {
    getItem: vi.fn((k) => (map.has(k) ? map.get(k) : null)),
    setItem: vi.fn((k, v) => {
      map.set(k, String(v));
    }),
    removeItem: vi.fn((k) => {
      map.delete(k);
    }),
    clear: vi.fn(() => {
      map.clear();
    }),
    key: vi.fn((i) => Array.from(map.keys())[i] ?? null),
    get length() {
      return map.size;
    },
  };
  vi.spyOn(window, "sessionStorage", "get").mockReturnValue(mock);
  return { mock, map };
}

function stubSessionStorageUnavailable() {
  return vi
    .spyOn(window, "sessionStorage", "get")
    .mockImplementation(() => {
      throw new Error("blocked");
    });
}

function stubCrypto(value) {
  return vi.stubGlobal("crypto", value);
}

async function readBeaconBody(call) {
  const [, blob] = call;
  return JSON.parse(await blob.text());
}

// --- Cleanup ----------------------------------------------------------------

afterEach(() => {
  window.history.pushState = originalPushState;
  window.history.replaceState = originalReplaceState;
  vi.restoreAllMocks();
  vi.unstubAllGlobals();
});

// --- Tests ------------------------------------------------------------------

describe("init()", () => {
  it("sends a pageview to the configured domain", async () => {
    const sendBeacon = stubSendBeacon();
    const { init } = await loadFresh();

    init({ domain: "example.com" });

    expect(sendBeacon).toHaveBeenCalledTimes(1);
    const [url, blob] = sendBeacon.mock.calls[0];
    expect(url).toBe("/v1/collect");
    expect(blob.type).toBe("application/json");
    const body = await readBeaconBody(sendBeacon.mock.calls[0]);
    expect(body).toMatchObject({
      d: "example.com",
      n: "pageview",
    });
    expect(typeof body.sid).toBe("string");
    expect(body.sid.length).toBeGreaterThan(0);
  });

  it("defaults the domain to window.location.hostname", async () => {
    stubLocation("https://docs.example.com/path");
    const sendBeacon = stubSendBeacon();
    const { init } = await loadFresh();

    init();

    expect(sendBeacon).toHaveBeenCalledTimes(1);
    const body = await readBeaconBody(sendBeacon.mock.calls[0]);
    expect(body.d).toBe("docs.example.com");
  });

  it("does not send anything when no domain is available", async () => {
    stubLocation("https://localhost/");
    const sendBeacon = stubSendBeacon();
    const fetch = stubFetch();
    const { init } = await loadFresh();

    init();

    expect(sendBeacon).not.toHaveBeenCalled();
    expect(fetch).not.toHaveBeenCalled();
  });

  it("honors autoPageviews: false on init", async () => {
    const sendBeacon = stubSendBeacon();
    const { init } = await loadFresh();

    init({ domain: "example.com", autoPageviews: false });

    expect(sendBeacon).not.toHaveBeenCalled();
  });

  it("uses the configured endpoint instead of the script origin", async () => {
    stubCurrentScript(makeFakeScript({ src: "https://cdn.glossia.ai/web.js" }));
    const sendBeacon = stubSendBeacon();
    const { init } = await loadFresh();

    init({
      domain: "example.com",
      endpoint: "https://api.example.com/v1/collect",
    });

    expect(sendBeacon).toHaveBeenCalledTimes(1);
    const [url] = sendBeacon.mock.calls[0];
    expect(url).toBe("https://api.example.com/v1/collect");
  });

  it("derives the endpoint from the current script src when none is provided", async () => {
    stubCurrentScript(makeFakeScript({ src: "https://cdn.glossia.ai/web.js" }));
    const sendBeacon = stubSendBeacon();
    const { init } = await loadFresh();

    init({ domain: "example.com" });

    const [url] = sendBeacon.mock.calls[0];
    expect(url).toBe("https://cdn.glossia.ai/v1/collect");
  });
});

describe("track() and pageview()", () => {
  it("sends the event name provided to track()", async () => {
    const sendBeacon = stubSendBeacon();
    const { init, track } = await loadFresh();

    init({ domain: "example.com", autoPageviews: false });
    track("signup");

    expect(sendBeacon).toHaveBeenCalledTimes(1);
    const body = await readBeaconBody(sendBeacon.mock.calls[0]);
    expect(body.n).toBe("signup");
  });

  it("includes the referrer and the page URL in every event", async () => {
    stubReferrer("https://google.com/search");
    stubLocation("https://example.com/landing");
    const sendBeacon = stubSendBeacon();
    const { init, track } = await loadFresh();

    init({ domain: "example.com", autoPageviews: false });
    track("signup");

    const body = await readBeaconBody(sendBeacon.mock.calls[0]);
    expect(body.u).toBe("https://example.com/landing");
    expect(body.r).toBe("https://google.com/search");
  });
});

describe("session id", () => {
  it("reuses the same session id across events in the same tab", async () => {
    stubSessionStorage();
    const sendBeacon = stubSendBeacon();
    const { init, track } = await loadFresh();

    init({ domain: "example.com", autoPageviews: false });
    const firstSid = JSON.parse(await sendBeacon.mock.calls[0][1].text()).sid;

    track("signup");
    const secondSid = JSON.parse(await sendBeacon.mock.calls[1][1].text()).sid;

    expect(secondSid).toBe(firstSid);
  });

  it("persists the session id in sessionStorage under __glossia_sid", async () => {
    const { mock, map } = stubSessionStorage();
    stubSendBeacon();
    const { init } = await loadFresh();

    init({ domain: "example.com", autoPageviews: false });

    expect(mock.setItem).toHaveBeenCalledWith(
      "__glossia_sid",
      expect.any(String),
    );
    expect(map.get("__glossia_sid")).toMatch(/^[0-9a-f-]{8,}$/i);
  });

  it("generates a new id when sessionStorage is unavailable", async () => {
    stubSessionStorageUnavailable();
    const sendBeacon = stubSendBeacon();
    const { init, track } = await loadFresh();

    init({ domain: "example.com", autoPageviews: false });
    track("signup");

    // Both events still fire and share a session id even without storage.
    expect(sendBeacon).toHaveBeenCalledTimes(2);
    const first = JSON.parse(await sendBeacon.mock.calls[0][1].text());
    const second = JSON.parse(await sendBeacon.mock.calls[1][1].text());
    expect(first.sid).toBe(second.sid);
    expect(first.sid.length).toBeGreaterThan(0);
  });
});

describe("network transport", () => {
  it("prefers sendBeacon over fetch when beacon returns true", async () => {
    const sendBeacon = stubSendBeacon(true);
    const fetch = stubFetch();
    const { init } = await loadFresh();

    init({ domain: "example.com" });

    expect(sendBeacon).toHaveBeenCalledTimes(1);
    expect(fetch).not.toHaveBeenCalled();
  });

  it("falls back to fetch when sendBeacon returns false", async () => {
    const sendBeacon = stubSendBeacon(false);
    const fetch = stubFetch();
    const { init } = await loadFresh();

    init({ domain: "example.com" });

    expect(sendBeacon).toHaveBeenCalledTimes(1);
    expect(fetch).toHaveBeenCalledTimes(1);
    const [url, init_] = fetch.mock.calls[0];
    expect(url).toBe("/v1/collect");
    expect(init_.method).toBe("POST");
    expect(init_.headers["Content-Type"]).toBe("application/json");
    expect(init_.keepalive).toBe(true);
    expect(init_.credentials).toBe("omit");
  });

  it("falls back to fetch when navigator.sendBeacon is not a function", async () => {
    const sendBeacon = stubSendBeacon();
    const fetch = stubFetch();
    // Replace the spied sendBeacon with a non-function value to simulate a
    // browser that doesn't implement the Beacon API. The SDK guards with
    // `typeof ... === "function"` before calling it.
    Object.defineProperty(navigator, "sendBeacon", {
      value: undefined,
      configurable: true,
      writable: true,
    });
    const { init } = await loadFresh();

    init({ domain: "example.com" });

    expect(sendBeacon).not.toHaveBeenCalled();
    expect(fetch).toHaveBeenCalledTimes(1);
  });

  it("never throws when both sendBeacon and fetch fail", async () => {
    stubSendBeacon(false);
    stubFetch(() => {
      throw new Error("network down");
    });
    const { init, track } = await loadFresh();

    expect(() => {
      init({ domain: "example.com" });
      track("signup");
    }).not.toThrow();
  });
});

describe("history hooks", () => {
  it("fires a pageview on pushState and replaceState", async () => {
    const sendBeacon = stubSendBeacon();
    const { init } = await loadFresh();

    init({ domain: "example.com" });
    expect(sendBeacon).toHaveBeenCalledTimes(1); // initial pageview

    window.history.pushState(null, "", "/next");
    window.history.replaceState(null, "", "/next-2");

    // The hook fires via setTimeout(..., 0), so yield to the macrotask queue.
    await new Promise((resolve) => setTimeout(resolve, 0));

    expect(sendBeacon).toHaveBeenCalledTimes(3);
    const bodies = await Promise.all(
      sendBeacon.mock.calls.map((call) => readBeaconBody(call)),
    );
    expect(bodies.map((b) => b.n)).toEqual(["pageview", "pageview", "pageview"]);
  });

  it("fires a pageview on popstate", async () => {
    const sendBeacon = stubSendBeacon();
    // Spy on addEventListener so we can capture and invoke the SDK's popstate
    // handler directly. This avoids leaving a real listener on `window` and
    // also keeps the assertion independent of how popstate dispatches.
    const addEventListener = vi.spyOn(window, "addEventListener");
    const { init } = await loadFresh();

    init({ domain: "example.com" });
    expect(sendBeacon).toHaveBeenCalledTimes(1);

    const popstateCall = addEventListener.mock.calls.find(
      ([event]) => event === "popstate",
    );
    expect(popstateCall).toBeDefined();
    const popstateHandler = popstateCall[1];

    popstateHandler(new PopStateEvent("popstate"));
    await new Promise((resolve) => setTimeout(resolve, 0));

    expect(sendBeacon).toHaveBeenCalledTimes(2);
  });

  it("does not install history hooks when autoPageviews is false", async () => {
    const sendBeacon = stubSendBeacon();
    const addEventListener = vi.spyOn(window, "addEventListener");
    const { init } = await loadFresh();

    init({ domain: "example.com", autoPageviews: false });
    window.history.pushState(null, "", "/next");
    await new Promise((resolve) => setTimeout(resolve, 0));

    expect(sendBeacon).not.toHaveBeenCalled();
    // No popstate listener was registered because hookHistory was skipped.
    const popstateCalls = addEventListener.mock.calls.filter(
      ([event]) => event === "popstate",
    );
    expect(popstateCalls).toHaveLength(0);
  });
});

describe("auto-init from <script> tag", () => {
  it("uses data-domain and data-endpoint from the current script tag", async () => {
    stubCurrentScript(
      makeFakeScript({
        src: "https://cdn.glossia.ai/web.js",
        domain: "example.com",
        endpoint: "https://api.example.com/v1/collect",
      }),
    );
    const sendBeacon = stubSendBeacon();
    await loadFresh();

    expect(sendBeacon).toHaveBeenCalledTimes(1);
    const [url, blob] = sendBeacon.mock.calls[0];
    expect(url).toBe("https://api.example.com/v1/collect");
    const body = JSON.parse(await blob.text());
    expect(body.d).toBe("example.com");
  });

  it("falls back to window.location.hostname when no data-domain is set", async () => {
    stubLocation("https://example.com/landing");
    stubCurrentScript(makeFakeScript({ src: "https://cdn.glossia.ai/web.js" }));
    const sendBeacon = stubSendBeacon();
    await loadFresh();

    expect(sendBeacon).toHaveBeenCalledTimes(1);
    const body = JSON.parse(await sendBeacon.mock.calls[0][1].text());
    expect(body.d).toBe("example.com");
  });
});

describe("analytics resilience", () => {
  it("silently no-ops events when init() was never called", async () => {
    const sendBeacon = stubSendBeacon();
    const fetch = stubFetch();
    const { track, pageview } = await loadFresh();

    expect(() => {
      track("signup");
      pageview();
    }).not.toThrow();
    expect(sendBeacon).not.toHaveBeenCalled();
    expect(fetch).not.toHaveBeenCalled();
  });

  it("uses a uuid fallback when crypto.randomUUID is unavailable", async () => {
    stubCrypto({});
    const sendBeacon = stubSendBeacon();
    const { init } = await loadFresh();

    init({ domain: "example.com", autoPageviews: false });

    const body = JSON.parse(await sendBeacon.mock.calls[0][1].text());
    // The hex fallback is 32 chars (no dashes), unlike crypto.randomUUID.
    expect(body.sid).toMatch(/^[0-9a-f]{32}$/);
  });
});
