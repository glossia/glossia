import * as SecureStore from "expo-secure-store";
import { getLocales } from "expo-localization";
import { I18n } from "i18n-js";
import React, { createContext, useContext, useEffect, useMemo, useState } from "react";
import {
  SUPPORTED_LOCALES,
  SupportedLocale,
  TranslationKey,
  translations,
} from "./translations";

const LOCALE_STORAGE_KEY = "glossia.mobile.locale.v1";

const i18n = new I18n(translations);
i18n.defaultLocale = "en";
i18n.enableFallback = true;

type TranslationParams = Record<string, string | number | boolean | null | undefined>;

interface I18nContextValue {
  locale: SupportedLocale;
  isReady: boolean;
  supportedLocales: readonly SupportedLocale[];
  t: (key: TranslationKey, params?: TranslationParams) => string;
  setLocale: (locale: SupportedLocale) => Promise<void>;
  clearLocaleOverride: () => Promise<void>;
}

const I18nContext = createContext<I18nContextValue | null>(null);

function normalizeLocale(input?: string | null): SupportedLocale {
  const locale = (input || "").toLowerCase();

  if (locale.startsWith("es")) {
    return "es";
  }

  return "en";
}

function deviceLocale(): SupportedLocale {
  const locales = getLocales();
  const primary = locales[0];

  if (!primary) {
    return "en";
  }

  return normalizeLocale(primary.languageTag || primary.languageCode || null);
}

export function I18nProvider({ children }: { children: React.ReactNode }) {
  const [locale, setLocaleState] = useState<SupportedLocale>(deviceLocale());
  const [isReady, setIsReady] = useState(false);

  useEffect(() => {
    i18n.locale = locale;
  }, [locale]);

  useEffect(() => {
    let mounted = true;

    const load = async () => {
      try {
        const stored = await SecureStore.getItemAsync(LOCALE_STORAGE_KEY);
        const normalized = normalizeLocale(stored);

        if (mounted && stored) {
          setLocaleState(normalized);
        }
      } finally {
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

  const value = useMemo<I18nContextValue>(() => {
    return {
      locale,
      isReady,
      supportedLocales: SUPPORTED_LOCALES,
      t: (key, params) => i18n.t(key, { ...params, defaultValue: translations.en[key] }) as string,
      setLocale: async (nextLocale) => {
        setLocaleState(nextLocale);
        await SecureStore.setItemAsync(LOCALE_STORAGE_KEY, nextLocale);
      },
      clearLocaleOverride: async () => {
        await SecureStore.deleteItemAsync(LOCALE_STORAGE_KEY);
        setLocaleState(deviceLocale());
      },
    };
  }, [isReady, locale]);

  return <I18nContext.Provider value={value}>{children}</I18nContext.Provider>;
}

export function useI18n() {
  const context = useContext(I18nContext);

  if (!context) {
    throw new Error("useI18n must be used inside I18nProvider.");
  }

  return context;
}
