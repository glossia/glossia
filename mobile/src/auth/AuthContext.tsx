import * as SecureStore from "expo-secure-store";
import React, { createContext, useContext, useEffect, useMemo, useState } from "react";
import { OAuthTokenResponse } from "../api/types";

type AuthStatus = "loading" | "signed_out" | "signed_in";

interface Session {
  accessToken: string;
  refreshToken?: string;
  tokenType: string;
  expiresAtMs: number;
}

interface AuthContextValue {
  status: AuthStatus;
  session: Session | null;
  signInFromToken: (tokenResponse: OAuthTokenResponse) => Promise<void>;
  signOut: () => Promise<void>;
}

const AuthContext = createContext<AuthContextValue | null>(null);

const SESSION_STORAGE_KEY = "glossia.mobile.session.v1";

function isValidSession(session: Session): boolean {
  return session.expiresAtMs > Date.now() + 15_000;
}

function toSession(tokenResponse: OAuthTokenResponse): Session {
  return {
    accessToken: tokenResponse.access_token,
    refreshToken: tokenResponse.refresh_token,
    tokenType: tokenResponse.token_type,
    expiresAtMs: Date.now() + tokenResponse.expires_in * 1000,
  };
}

export function AuthProvider({ children }: { children: React.ReactNode }) {
  const [status, setStatus] = useState<AuthStatus>("loading");
  const [session, setSession] = useState<Session | null>(null);

  useEffect(() => {
    let isMounted = true;

    const load = async () => {
      try {
        const raw = await SecureStore.getItemAsync(SESSION_STORAGE_KEY);

        if (!raw) {
          if (isMounted) {
            setStatus("signed_out");
          }
          return;
        }

        const parsed = JSON.parse(raw) as Session;

        if (isMounted && isValidSession(parsed)) {
          setSession(parsed);
          setStatus("signed_in");
          return;
        }

        await SecureStore.deleteItemAsync(SESSION_STORAGE_KEY);

        if (isMounted) {
          setSession(null);
          setStatus("signed_out");
        }
      } catch {
        if (isMounted) {
          setSession(null);
          setStatus("signed_out");
        }
      }
    };

    void load();

    return () => {
      isMounted = false;
    };
  }, []);

  const value = useMemo<AuthContextValue>(() => {
    return {
      status,
      session,
      signInFromToken: async (tokenResponse: OAuthTokenResponse) => {
        const nextSession = toSession(tokenResponse);
        await SecureStore.setItemAsync(SESSION_STORAGE_KEY, JSON.stringify(nextSession));
        setSession(nextSession);
        setStatus("signed_in");
      },
      signOut: async () => {
        await SecureStore.deleteItemAsync(SESSION_STORAGE_KEY);
        setSession(null);
        setStatus("signed_out");
      },
    };
  }, [status, session]);

  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>;
}

export function useAuth(): AuthContextValue {
  const context = useContext(AuthContext);

  if (!context) {
    throw new Error("useAuth must be used inside AuthProvider.");
  }

  return context;
}
