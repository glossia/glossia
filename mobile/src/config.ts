import { Platform } from "react-native";

export const PRODUCTION_GLOSSIA_BASE_URL = "https://glossia.ai";
export const DEV_LOCALHOST_IOS_BASE_URL = "http://127.0.0.1:4050";
export const DEV_LOCALHOST_ANDROID_BASE_URL = "http://10.0.2.2:4050";

const platformDefault = Platform.select({
  android: DEV_LOCALHOST_ANDROID_BASE_URL,
  ios: DEV_LOCALHOST_IOS_BASE_URL,
  default: DEV_LOCALHOST_IOS_BASE_URL,
});

export function normalizeBaseUrl(url: string): string | null {
  const trimmed = url.trim();
  if (!trimmed) return null;

  const withScheme = /^https?:\/\//i.test(trimmed) ? trimmed : `http://${trimmed}`;
  const withoutTrailingSlash = withScheme.replace(/\/+$/, "");

  try {
    const parsed = new URL(withoutTrailingSlash);
    if (!parsed.hostname) return null;
    if (parsed.protocol !== "http:" && parsed.protocol !== "https:") return null;
    return withoutTrailingSlash;
  } catch {
    return null;
  }
}

export function defaultGlossiaBaseUrl(): string {
  const envBaseUrl = process.env.EXPO_PUBLIC_GLOSSIA_BASE_URL;
  const normalizedEnv = envBaseUrl ? normalizeBaseUrl(envBaseUrl) : null;

  if (normalizedEnv) return normalizedEnv;
  if (process.env.NODE_ENV === "production") return PRODUCTION_GLOSSIA_BASE_URL;

  // Default to production even in development (per request), but keep platform
  // local URLs available through the dev override UI.
  return PRODUCTION_GLOSSIA_BASE_URL || platformDefault || DEV_LOCALHOST_IOS_BASE_URL;
}

export function defaultDevCandidates(): string[] {
  return [
    PRODUCTION_GLOSSIA_BASE_URL,
    DEV_LOCALHOST_IOS_BASE_URL,
    DEV_LOCALHOST_ANDROID_BASE_URL,
  ];
}

export const GLOSSIA_OAUTH_CLIENT_ID =
  process.env.EXPO_PUBLIC_GLOSSIA_OAUTH_CLIENT_ID ||
  "6b7a2d2b-5f2a-4a57-9ea5-31a4d5b0c5f9";

export const GLOSSIA_OAUTH_SCOPES =
  process.env.EXPO_PUBLIC_GLOSSIA_OAUTH_SCOPES || "account:read project:read";
