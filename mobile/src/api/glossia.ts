import {
  AccountsResponse,
  OAuthTokenResponse,
  ProjectsResponse,
} from "./types";

const AUTHORIZATION_CODE_GRANT_TYPE = "authorization_code";
const REFRESH_TOKEN_GRANT_TYPE = "refresh_token";
const REQUEST_TIMEOUT_MS = 12_000;

type FormBody = Record<string, string | undefined>;

export class GlossiaApiError extends Error {
  readonly status: number;
  readonly code: string;
  readonly description: string;

  constructor(status: number, code: string, description: string) {
    super(description);
    this.status = status;
    this.code = code;
    this.description = description;
  }
}

function buildUrl(baseUrl: string, path: string): string {
  const root = baseUrl.replace(/\/+$/, "");
  const suffix = path.startsWith("/") ? path : `/${path}`;
  return `${root}${suffix}`;
}

function toFormEncoded(body: FormBody): string {
  const searchParams = new URLSearchParams();

  Object.entries(body).forEach(([key, value]) => {
    if (typeof value === "string") {
      searchParams.append(key, value);
    }
  });

  return searchParams.toString();
}

async function readJson(response: Response): Promise<unknown> {
  const text = await response.text();

  if (!text) {
    return {};
  }

  try {
    return JSON.parse(text) as unknown;
  } catch {
    return {};
  }
}

function getStringField(payload: unknown, key: string): string | undefined {
  if (!payload || typeof payload !== "object") {
    return undefined;
  }

  const value = (payload as Record<string, unknown>)[key];
  return typeof value === "string" ? value : undefined;
}

function targetUrl(input: RequestInfo): string {
  if (typeof input === "string") {
    return input;
  }

  if (input instanceof URL) {
    return input.toString();
  }

  if (typeof input === "object" && input && "url" in input) {
    const maybeUrl = (input as { url?: unknown }).url;
    if (typeof maybeUrl === "string") {
      return maybeUrl;
    }
  }

  return "the Glossia server";
}

async function requestJson<T>(input: RequestInfo, init?: RequestInit): Promise<T> {
  let response: Response;
  const controller = new AbortController();
  const timeoutId = setTimeout(() => {
    controller.abort();
  }, REQUEST_TIMEOUT_MS);
  const target = targetUrl(input);

  try {
    response = await fetch(input, {
      ...init,
      signal: controller.signal,
    });
  } catch (caughtError: unknown) {
    if (caughtError instanceof Error && caughtError.name === "AbortError") {
      throw new GlossiaApiError(
        0,
        "network_timeout",
        `Request to ${target} timed out after ${REQUEST_TIMEOUT_MS / 1000}s.`,
      );
    }

    throw new GlossiaApiError(
      0,
      "network_error",
      `Could not reach ${target}. Check the backend URL in app settings or EXPO_PUBLIC_GLOSSIA_BASE_URL.`,
    );
  } finally {
    clearTimeout(timeoutId);
  }

  const payload = await readJson(response);

  if (!response.ok) {
    const code = getStringField(payload, "error") || "request_failed";
    const description =
      getStringField(payload, "error_description") ||
      getStringField(payload, "message") ||
      `Request failed with status ${response.status}.`;

    throw new GlossiaApiError(response.status, code, description);
  }

  return payload as T;
}

export async function exchangeAuthorizationCode(params: {
  baseUrl: string;
  clientId: string;
  code: string;
  redirectUri: string;
  codeVerifier: string;
}): Promise<OAuthTokenResponse> {
  const body = toFormEncoded({
    grant_type: AUTHORIZATION_CODE_GRANT_TYPE,
    client_id: params.clientId,
    code: params.code,
    redirect_uri: params.redirectUri,
    code_verifier: params.codeVerifier,
  });

  return requestJson<OAuthTokenResponse>(buildUrl(params.baseUrl, "/oauth/token"), {
    method: "POST",
    headers: {
      "Content-Type": "application/x-www-form-urlencoded",
    },
    body,
  });
}

export async function refreshAccessToken(params: {
  baseUrl: string;
  clientId: string;
  refreshToken: string;
}): Promise<OAuthTokenResponse> {
  const body = toFormEncoded({
    grant_type: REFRESH_TOKEN_GRANT_TYPE,
    client_id: params.clientId,
    refresh_token: params.refreshToken,
  });

  return requestJson<OAuthTokenResponse>(buildUrl(params.baseUrl, "/oauth/token"), {
    method: "POST",
    headers: {
      "Content-Type": "application/x-www-form-urlencoded",
    },
    body,
  });
}

export async function fetchAccounts(params: {
  baseUrl: string;
  accessToken: string;
}): Promise<AccountsResponse> {
  return requestJson<AccountsResponse>(buildUrl(params.baseUrl, "/api/accounts"), {
    method: "GET",
    headers: {
      Authorization: `Bearer ${params.accessToken}`,
    },
  });
}

export async function fetchProjects(params: {
  baseUrl: string;
  accessToken: string;
  handle: string;
}): Promise<ProjectsResponse> {
  return requestJson<ProjectsResponse>(
    buildUrl(params.baseUrl, `/api/${encodeURIComponent(params.handle)}/projects`),
    {
      method: "GET",
      headers: {
        Authorization: `Bearer ${params.accessToken}`,
      },
    },
  );
}
