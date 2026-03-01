import * as ExpoLinking from "expo-linking";
import * as SecureStore from "expo-secure-store";
import React, { createContext, useContext, useEffect, useMemo, useState } from "react";
import { defaultDevCandidates, defaultGlossiaBaseUrl, normalizeBaseUrl } from "../config";

const DEV_BASE_URL_STORAGE_KEY = "glossia.mobile.dev_base_url.v1";
const HEALTHCHECK_TIMEOUT_MS = 5000;

interface SaveResult {
  ok: boolean;
  error?: string;
}

interface BackendUrlContextValue {
  baseUrl: string;
  isReady: boolean;
  devOverrideUrl: string | null;
  devCandidates: string[];
  saveDevOverride: (nextUrl: string) => Promise<SaveResult>;
  clearDevOverride: () => Promise<void>;
}

const BackendUrlContext = createContext<BackendUrlContextValue | null>(null);

function metroLanCandidate(): string | null {
  if (!__DEV__) return null;

  const expoUrl = ExpoLinking.createURL("/");
  const match = expoUrl.match(/^[a-z]+:\/\/([^/:?#]+)(?::\d+)?/i);
  const host = match?.[1];

  if (!host) return null;
  if (host === "127.0.0.1" || host === "localhost") return null;
  if (host === "10.0.2.2") return null;

  return `http://${host}:4050`;
}

async function validateBaseUrl(url: string): Promise<SaveResult> {
  const controller = new AbortController();
  const timeout = setTimeout(() => controller.abort(), HEALTHCHECK_TIMEOUT_MS);

  try {
    const response = await fetch(`${url}/up`, { signal: controller.signal });

    if (!response.ok) {
      return { ok: false, error: `Healthcheck failed (${response.status}).` };
    }

    return { ok: true };
  } catch (error: unknown) {
    if (error instanceof Error && error.name === "AbortError") {
      return { ok: false, error: "Healthcheck timed out." };
    }

    return { ok: false, error: "Could not reach this backend URL." };
  } finally {
    clearTimeout(timeout);
  }
}

function uniqueUrls(urls: Array<string | null | undefined>): string[] {
  const seen = new Set<string>();
  const result: string[] = [];

  for (const url of urls) {
    if (!url) continue;
    const normalized = normalizeBaseUrl(url);
    if (!normalized) continue;
    if (seen.has(normalized)) continue;
    seen.add(normalized);
    result.push(normalized);
  }

  return result;
}

export function BackendUrlProvider({ children }: { children: React.ReactNode }) {
  const [isReady, setIsReady] = useState(false);
  const [baseUrl, setBaseUrl] = useState(defaultGlossiaBaseUrl());
  const [devOverrideUrl, setDevOverrideUrl] = useState<string | null>(null);

  useEffect(() => {
    let mounted = true;

    const load = async () => {
      if (!__DEV__) {
        if (mounted) {
          setIsReady(true);
        }
        return;
      }

      try {
        const stored = await SecureStore.getItemAsync(DEV_BASE_URL_STORAGE_KEY);
        const normalizedStored = stored ? normalizeBaseUrl(stored) : null;

        if (mounted) {
          if (normalizedStored) {
            setDevOverrideUrl(normalizedStored);
            setBaseUrl(normalizedStored);
          }

          setIsReady(true);
        }
      } catch {
        if (mounted) {
          setIsReady(true);
        }
      }
    };

    void load();

    return () => {
      mounted = false;
    };
  }, []);

  const value = useMemo<BackendUrlContextValue>(() => {
    const candidates = uniqueUrls([...defaultDevCandidates(), metroLanCandidate(), baseUrl]);

    return {
      baseUrl,
      isReady,
      devOverrideUrl,
      devCandidates: candidates,
      saveDevOverride: async (nextUrl: string) => {
        const normalized = normalizeBaseUrl(nextUrl);
        if (!normalized) {
          return { ok: false, error: "Please enter a valid http(s) URL." };
        }

        const validation = await validateBaseUrl(normalized);
        if (!validation.ok) {
          return validation;
        }

        if (__DEV__) {
          await SecureStore.setItemAsync(DEV_BASE_URL_STORAGE_KEY, normalized);
          setDevOverrideUrl(normalized);
        }

        setBaseUrl(normalized);
        return { ok: true };
      },
      clearDevOverride: async () => {
        if (__DEV__) {
          await SecureStore.deleteItemAsync(DEV_BASE_URL_STORAGE_KEY);
        }

        setDevOverrideUrl(null);
        setBaseUrl(defaultGlossiaBaseUrl());
      },
    };
  }, [baseUrl, devOverrideUrl, isReady]);

  return <BackendUrlContext.Provider value={value}>{children}</BackendUrlContext.Provider>;
}

export function useBackendUrl() {
  const context = useContext(BackendUrlContext);
  if (!context) {
    throw new Error("useBackendUrl must be used inside BackendUrlProvider.");
  }

  return context;
}
