import { NativeStackScreenProps } from "@react-navigation/native-stack";
import { useFocusEffect } from "@react-navigation/native";
import React, { useCallback, useLayoutEffect, useState } from "react";
import {
  ActivityIndicator,
  FlatList,
  Pressable,
  StyleSheet,
  Text,
  View,
} from "react-native";
import { fetchAccounts, GlossiaApiError } from "../api/glossia";
import { AccountSummary } from "../api/types";
import { useAuth } from "../auth/AuthContext";
import { GlassBackground } from "../components/GlassBackground";
import { GlassSurface } from "../components/GlassSurface";
import { useBackendUrl } from "../dev/BackendUrlContext";
import { useI18n } from "../i18n/I18nContext";
import { RootStackParamList } from "../navigation/types";
import { appTheme } from "../theme/theme";

type Props = NativeStackScreenProps<RootStackParamList, "Accounts">;

export function AccountsScreen({ navigation }: Props) {
  const { session, signOut } = useAuth();
  const { baseUrl } = useBackendUrl();
  const { t } = useI18n();
  const [loading, setLoading] = useState(true);
  const [accounts, setAccounts] = useState<AccountSummary[]>([]);
  const [error, setError] = useState<string | null>(null);

  const loadAccounts = useCallback(async () => {
    if (!session) {
      return;
    }

    setLoading(true);
    setError(null);

    try {
      const response = await fetchAccounts({
        baseUrl,
        accessToken: session.accessToken,
      });
      setAccounts(response.accounts || []);
    } catch (caughtError: unknown) {
      if (caughtError instanceof GlossiaApiError) {
        setError(caughtError.description);
      } else {
        setError(t("accounts_error_load"));
      }
    } finally {
      setLoading(false);
    }
  }, [baseUrl, session, t]);

  useFocusEffect(
    useCallback(() => {
      void loadAccounts();
    }, [loadAccounts]),
  );

  useLayoutEffect(() => {
    navigation.setOptions({
      headerRight: () => (
        <Pressable
          style={styles.headerButton}
          onPress={() => {
            void signOut();
          }}
        >
          <Text style={styles.headerButtonText}>{t("accounts_sign_out")}</Text>
        </Pressable>
      ),
    });
  }, [navigation, signOut, t]);

  if (loading) {
    return (
      <View style={styles.center}>
        <GlassBackground />
        <GlassSurface style={styles.loadingCard}>
          <ActivityIndicator color={appTheme.colors.primary} />
          <Text style={styles.loadingText}>{t("accounts_loading")}</Text>
        </GlassSurface>
      </View>
    );
  }

  return (
    <View style={styles.container}>
      <GlassBackground />
      {error ? <Text style={styles.errorText}>{error}</Text> : null}
      <FlatList
        data={accounts}
        keyExtractor={(account) => account.handle}
        contentContainerStyle={styles.listContent}
        ItemSeparatorComponent={() => <View style={styles.separator} />}
        renderItem={({ item }) => (
          <Pressable
            style={styles.cardPressable}
            onPress={() => {
              navigation.navigate("Account", {
                handle: item.handle,
                type: item.type,
                visibility: item.visibility,
              });
            }}
          >
            <GlassSurface style={styles.card}>
              <Text style={styles.cardTitle}>{item.handle}</Text>
              <Text style={styles.cardSubtitle}>
                {t("accounts_meta", { type: item.type, visibility: item.visibility })}
              </Text>
            </GlassSurface>
          </Pressable>
        )}
        ListEmptyComponent={
          <GlassSurface style={styles.emptyState}>
            <Text style={styles.emptyTitle}>{t("accounts_empty_title")}</Text>
            <Text style={styles.emptyText}>{t("accounts_empty_text")}</Text>
          </GlassSurface>
        }
      />
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: appTheme.colors.bg,
    position: "relative",
  },
  listContent: {
    padding: appTheme.spacing.x4,
  },
  separator: {
    height: appTheme.spacing.x3,
  },
  cardPressable: {
    borderRadius: appTheme.radius.md,
  },
  card: {
    borderRadius: appTheme.radius.md,
    padding: appTheme.spacing.x4,
    gap: appTheme.spacing.x1,
  },
  cardTitle: {
    fontSize: 18,
    fontWeight: "700",
    color: appTheme.colors.text,
  },
  cardSubtitle: {
    fontSize: 14,
    color: appTheme.colors.textSecondary,
  },
  center: {
    flex: 1,
    alignItems: "center",
    justifyContent: "center",
    backgroundColor: appTheme.colors.bg,
    gap: appTheme.spacing.x2,
    position: "relative",
  },
  loadingText: {
    color: appTheme.colors.textSecondary,
    fontSize: 14,
  },
  loadingCard: {
    borderRadius: appTheme.radius.md,
    paddingHorizontal: appTheme.spacing.x5,
    paddingVertical: appTheme.spacing.x4,
    gap: appTheme.spacing.x2,
    alignItems: "center",
  },
  errorText: {
    margin: appTheme.spacing.x4,
    padding: appTheme.spacing.x3,
    borderRadius: appTheme.radius.md,
    borderWidth: 1,
    borderColor: appTheme.colors.error,
    color: appTheme.colors.error,
    backgroundColor: appTheme.colors.errorSoft,
  },
  emptyState: {
    padding: appTheme.spacing.x6,
    borderRadius: appTheme.radius.md,
    gap: appTheme.spacing.x2,
  },
  emptyTitle: {
    fontSize: 16,
    fontWeight: "700",
    color: appTheme.colors.text,
  },
  emptyText: {
    fontSize: 14,
    color: appTheme.colors.textSecondary,
  },
  headerButton: {
    paddingHorizontal: appTheme.spacing.x2,
    paddingVertical: appTheme.spacing.x1,
  },
  headerButtonText: {
    fontSize: 14,
    color: appTheme.colors.primary,
    fontWeight: "600",
  },
});
