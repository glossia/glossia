import * as AuthSession from "expo-auth-session";
import * as WebBrowser from "expo-web-browser";
import React, { useCallback, useEffect, useMemo, useState } from "react";
import {
  ActivityIndicator,
  Modal,
  Pressable,
  ScrollView,
  StyleSheet,
  Text,
  TextInput,
  View,
} from "react-native";
import { exchangeAuthorizationCode, GlossiaApiError } from "../api/glossia";
import { useAuth } from "../auth/AuthContext";
import { GlassBackground } from "../components/GlassBackground";
import { GlassSurface } from "../components/GlassSurface";
import { GLOSSIA_OAUTH_CLIENT_ID, GLOSSIA_OAUTH_SCOPES } from "../config";
import { useBackendUrl } from "../dev/BackendUrlContext";
import { useI18n } from "../i18n/I18nContext";
import { appTheme } from "../theme/theme";

WebBrowser.maybeCompleteAuthSession();

function scopeList(scope: string): string[] {
  return scope
    .split(/\s+/)
    .map((entry) => entry.trim())
    .filter(Boolean);
}

function isSupportedRedirectUri(redirectUri: string): boolean {
  if (redirectUri === "glossia://oauth/callback") return true;
  if (redirectUri === "https://glossia.ai/oauth/callback") return true;

  return /^exp:\/\/(localhost|127\.0\.0\.1):(8081|19000)\/--\/oauth\/callback$/.test(redirectUri);
}

export function LoginScreen() {
  const { signInFromToken } = useAuth();
  const { t, locale, supportedLocales, setLocale, clearLocaleOverride } = useI18n();
  const { baseUrl, devOverrideUrl, devCandidates, saveDevOverride, clearDevOverride } = useBackendUrl();

  const [isAuthorizing, setIsAuthorizing] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [showBackendModal, setShowBackendModal] = useState(false);
  const [backendInput, setBackendInput] = useState(baseUrl);
  const [backendSaveError, setBackendSaveError] = useState<string | null>(null);
  const [backendSaving, setBackendSaving] = useState(false);

  const redirectUri = useMemo(
    () =>
      AuthSession.makeRedirectUri({
        native: "glossia://oauth/callback",
        scheme: "glossia",
        path: "oauth/callback",
        preferLocalhost: true,
      }),
    [],
  );

  const discovery = useMemo(
    () => ({
      authorizationEndpoint: `${baseUrl}/oauth/authorize`,
      tokenEndpoint: `${baseUrl}/oauth/token`,
      revocationEndpoint: `${baseUrl}/oauth/revoke`,
    }),
    [baseUrl],
  );

  const scopes = useMemo(() => scopeList(GLOSSIA_OAUTH_SCOPES), []);
  const redirectUriSupported = useMemo(() => isSupportedRedirectUri(redirectUri), [redirectUri]);

  const authSessionError = useCallback(
    (result: AuthSession.AuthSessionResult): string => {
      if (result.type === "error") {
        const description = result.error?.params?.error_description || result.params.error_description;
        return description || t("login_error_generic");
      }

      if (result.type === "cancel" || result.type === "dismiss") {
        return t("login_error_cancelled");
      }

      if (result.type === "locked") {
        return t("login_error_locked");
      }

      return t("login_error_generic");
    },
    [t],
  );

  const [request, , promptAsync] = AuthSession.useAuthRequest(
    {
      clientId: GLOSSIA_OAUTH_CLIENT_ID,
      redirectUri,
      responseType: AuthSession.ResponseType.Code,
      usePKCE: true,
      scopes,
    },
    discovery,
  );

  const startLogin = useCallback(async () => {
    if (!request) {
      setError(t("login_error_auth_loading"));
      return;
    }

    setError(null);
    setIsAuthorizing(true);

    try {
      const authRequest = request;
      const authResult = await promptAsync();

      if (authResult.type !== "success") {
        setError(authSessionError(authResult));
        return;
      }

      const code = authResult.params.code;
      if (!code) {
        setError(t("login_error_no_code"));
        return;
      }

      if (!authRequest.codeVerifier) {
        setError(t("login_error_missing_pkce_verifier"));
        return;
      }

      const tokenResponse = await exchangeAuthorizationCode({
        baseUrl,
        clientId: GLOSSIA_OAUTH_CLIENT_ID,
        code,
        redirectUri,
        codeVerifier: authRequest.codeVerifier,
      });

      await signInFromToken(tokenResponse);
    } catch (caughtError: unknown) {
      if (caughtError instanceof GlossiaApiError) {
        setError(caughtError.description);
      } else {
        setError(t("login_error_generic"));
      }
    } finally {
      setIsAuthorizing(false);
    }
  }, [authSessionError, baseUrl, promptAsync, redirectUri, request, signInFromToken, t]);

  useEffect(() => {
    if (!showBackendModal) {
      setBackendInput(baseUrl);
      setBackendSaveError(null);
    }
  }, [baseUrl, showBackendModal]);

  const saveBackendUrl = useCallback(async () => {
    setBackendSaving(true);
    setBackendSaveError(null);

    const result = await saveDevOverride(backendInput);
    setBackendSaving(false);

    if (!result.ok) {
      setBackendSaveError(result.error || t("login_backend_save_error"));
      return;
    }

    setShowBackendModal(false);
  }, [backendInput, saveDevOverride, t]);

  return (
    <ScrollView style={styles.scroll} contentContainerStyle={styles.content}>
      <GlassBackground />

      <GlassSurface style={styles.card}>
        <Text style={styles.eyebrow}>{t("login_eyebrow")}</Text>
        <Text style={styles.title}>{t("login_title")}</Text>
        <Text style={styles.subtitle}>{t("login_subtitle")}</Text>
        <Text style={styles.endpointText}>{t("login_endpoint_label", { baseUrl })}</Text>
        <Text style={styles.endpointText}>{t("login_redirect_uri_label", { redirectUri })}</Text>

        {__DEV__ ? (
          <Pressable
            style={styles.devButton}
            onPress={() => {
              setShowBackendModal(true);
            }}
          >
            <Text style={styles.devButtonText}>{t("login_change_backend_url")}</Text>
          </Pressable>
        ) : null}

        <Pressable
          style={[
            styles.primaryButton,
            (isAuthorizing || !request || !redirectUriSupported) && styles.primaryButtonDisabled,
          ]}
          onPress={() => {
            void startLogin();
          }}
          disabled={isAuthorizing || !request || !redirectUriSupported}
        >
          {isAuthorizing ? (
            <ActivityIndicator color={appTheme.colors.textOnAccent} />
          ) : (
            <Text style={styles.primaryButtonText}>{t("login_continue_to_sign_in")}</Text>
          )}
        </Pressable>

        {!request ? <Text style={styles.helperText}>{t("login_preparing_sign_in")}</Text> : null}
        {!redirectUriSupported ? (
          <Text style={styles.warningText}>{t("login_warning_redirect_uri_unsupported")}</Text>
        ) : null}

        {error ? <Text style={styles.errorText}>{error}</Text> : null}
      </GlassSurface>

      {__DEV__ ? (
        <Modal
          visible={showBackendModal}
          animationType="slide"
          transparent
          onRequestClose={() => setShowBackendModal(false)}
        >
          <View style={styles.modalBackdrop}>
            <GlassSurface style={styles.modalCard}>
              <Text style={styles.modalTitle}>{t("login_backend_modal_title")}</Text>
              <Text style={styles.modalSubtitle}>{t("login_backend_modal_subtitle")}</Text>

              <Text style={styles.localeLabel}>{t("login_language_label")}</Text>
              <View style={styles.localeRow}>
                {supportedLocales.map((candidateLocale) => (
                  <Pressable
                    key={candidateLocale}
                    style={[
                      styles.candidateChip,
                      candidateLocale === locale && styles.candidateChipActive,
                    ]}
                    onPress={() => {
                      void setLocale(candidateLocale);
                    }}
                  >
                    <Text
                      style={[
                        styles.candidateChipText,
                        candidateLocale === locale && styles.candidateChipTextActive,
                      ]}
                    >
                      {candidateLocale.toUpperCase()}
                    </Text>
                  </Pressable>
                ))}
                <Pressable
                  style={styles.candidateChip}
                  onPress={() => {
                    void clearLocaleOverride();
                  }}
                >
                  <Text style={styles.candidateChipText}>{t("common_system")}</Text>
                </Pressable>
              </View>

              <TextInput
                value={backendInput}
                onChangeText={setBackendInput}
                autoCapitalize="none"
                autoCorrect={false}
                placeholder={t("login_backend_input_placeholder")}
                style={styles.modalInput}
              />

              <View style={styles.candidateList}>
                {devCandidates.map((candidate) => (
                  <Pressable
                    key={candidate}
                    style={styles.candidateChip}
                    onPress={() => setBackendInput(candidate)}
                  >
                    <Text style={styles.candidateChipText}>{candidate}</Text>
                  </Pressable>
                ))}
              </View>

              {backendSaveError ? <Text style={styles.modalError}>{backendSaveError}</Text> : null}

              <View style={styles.modalActions}>
                <Pressable
                  style={[styles.modalButton, styles.modalSecondaryButton]}
                  onPress={() => setShowBackendModal(false)}
                  disabled={backendSaving}
                >
                  <Text style={styles.modalSecondaryButtonText}>{t("common_cancel")}</Text>
                </Pressable>

                <Pressable
                  style={[styles.modalButton, styles.modalSecondaryButton]}
                  onPress={() => {
                    void clearDevOverride();
                    setShowBackendModal(false);
                  }}
                  disabled={backendSaving}
                >
                  <Text style={styles.modalSecondaryButtonText}>{t("common_use_default")}</Text>
                </Pressable>

                <Pressable
                  style={[styles.modalButton, styles.modalPrimaryButton]}
                  onPress={() => {
                    void saveBackendUrl();
                  }}
                  disabled={backendSaving}
                >
                  {backendSaving ? (
                    <ActivityIndicator color={appTheme.colors.textOnAccent} />
                  ) : (
                    <Text style={styles.modalPrimaryButtonText}>{t("common_save")}</Text>
                  )}
                </Pressable>
              </View>

              <Text style={styles.modalFootnote}>
                {t("login_backend_current_override", {
                  value: devOverrideUrl || t("login_backend_override_none"),
                })}
              </Text>
            </GlassSurface>
          </View>
        </Modal>
      ) : null}
    </ScrollView>
  );
}

const styles = StyleSheet.create({
  scroll: {
    flex: 1,
    backgroundColor: appTheme.colors.bg,
  },
  content: {
    flexGrow: 1,
    justifyContent: "center",
    padding: appTheme.spacing.x6,
    position: "relative",
  },
  card: {
    borderRadius: appTheme.radius.lg,
    padding: appTheme.spacing.x6,
    gap: appTheme.spacing.x3,
  },
  eyebrow: {
    color: appTheme.colors.primary,
    fontSize: 12,
    fontWeight: "600",
    textTransform: "uppercase",
    letterSpacing: 0.6,
  },
  title: {
    fontSize: 24,
    fontWeight: "700",
    color: appTheme.colors.text,
  },
  subtitle: {
    fontSize: 15,
    lineHeight: 22,
    color: appTheme.colors.textSecondary,
  },
  endpointText: {
    fontSize: 12,
    color: appTheme.colors.textMuted,
  },
  devButton: {
    alignSelf: "flex-start",
    borderWidth: 1,
    borderColor: appTheme.colors.borderStrong,
    borderRadius: appTheme.radius.full,
    paddingHorizontal: appTheme.spacing.x3,
    paddingVertical: appTheme.spacing.x1,
  },
  devButtonText: {
    color: appTheme.colors.textSecondary,
    fontSize: 12,
    fontWeight: "600",
  },
  primaryButton: {
    marginTop: appTheme.spacing.x1,
    backgroundColor: appTheme.colors.primary,
    borderRadius: appTheme.radius.md,
    paddingVertical: appTheme.spacing.x3,
    alignItems: "center",
    justifyContent: "center",
  },
  primaryButtonDisabled: {
    opacity: 0.7,
  },
  primaryButtonText: {
    color: appTheme.colors.textOnAccent,
    fontSize: 16,
    fontWeight: "600",
  },
  helperText: {
    color: appTheme.colors.textSecondary,
    fontSize: 13,
  },
  warningText: {
    color: appTheme.colors.textSecondary,
    fontSize: 13,
    lineHeight: 19,
  },
  errorText: {
    color: appTheme.colors.error,
    fontSize: 14,
    lineHeight: 20,
  },
  modalBackdrop: {
    flex: 1,
    backgroundColor: "rgba(0,0,0,0.2)",
    justifyContent: "flex-end",
  },
  modalCard: {
    borderTopLeftRadius: appTheme.radius.lg,
    borderTopRightRadius: appTheme.radius.lg,
    padding: appTheme.spacing.x4,
    gap: appTheme.spacing.x2,
  },
  modalTitle: {
    color: appTheme.colors.text,
    fontSize: 18,
    fontWeight: "700",
  },
  modalSubtitle: {
    color: appTheme.colors.textSecondary,
    fontSize: 13,
    lineHeight: 18,
  },
  modalInput: {
    borderWidth: 1,
    borderColor: appTheme.colors.glassBorder,
    borderRadius: appTheme.radius.md,
    paddingHorizontal: appTheme.spacing.x3,
    paddingVertical: appTheme.spacing.x2,
    fontSize: 14,
    color: appTheme.colors.text,
    backgroundColor: appTheme.colors.glassSurfaceStrong,
  },
  localeLabel: {
    color: appTheme.colors.textSecondary,
    fontSize: 13,
    marginTop: appTheme.spacing.x1,
  },
  localeRow: {
    flexDirection: "row",
    flexWrap: "wrap",
    gap: appTheme.spacing.x2,
  },
  candidateList: {
    flexDirection: "row",
    flexWrap: "wrap",
    gap: appTheme.spacing.x2,
    marginTop: appTheme.spacing.x1,
  },
  candidateChip: {
    borderWidth: 1,
    borderColor: appTheme.colors.glassBorder,
    borderRadius: appTheme.radius.full,
    paddingHorizontal: appTheme.spacing.x2,
    paddingVertical: appTheme.spacing.x1,
    backgroundColor: appTheme.colors.glassSurfaceStrong,
  },
  candidateChipActive: {
    borderColor: appTheme.colors.primary,
    backgroundColor: appTheme.colors.primarySoft,
  },
  candidateChipText: {
    color: appTheme.colors.textSecondary,
    fontSize: 12,
  },
  candidateChipTextActive: {
    color: appTheme.colors.primary,
    fontWeight: "600",
  },
  modalError: {
    color: appTheme.colors.error,
    fontSize: 13,
  },
  modalActions: {
    flexDirection: "row",
    gap: appTheme.spacing.x2,
    marginTop: appTheme.spacing.x2,
  },
  modalButton: {
    flex: 1,
    minHeight: 40,
    borderRadius: appTheme.radius.md,
    alignItems: "center",
    justifyContent: "center",
    paddingHorizontal: appTheme.spacing.x2,
  },
  modalPrimaryButton: {
    backgroundColor: appTheme.colors.primary,
  },
  modalPrimaryButtonText: {
    color: appTheme.colors.textOnAccent,
    fontWeight: "600",
    fontSize: 14,
  },
  modalSecondaryButton: {
    borderWidth: 1,
    borderColor: appTheme.colors.glassBorder,
    backgroundColor: appTheme.colors.glassSurfaceStrong,
  },
  modalSecondaryButtonText: {
    color: appTheme.colors.textSecondary,
    fontWeight: "600",
    fontSize: 13,
  },
  modalFootnote: {
    marginTop: appTheme.spacing.x1,
    color: appTheme.colors.textMuted,
    fontSize: 12,
  },
});
