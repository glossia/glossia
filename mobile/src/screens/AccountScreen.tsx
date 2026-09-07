import { NativeStackScreenProps } from "@react-navigation/native-stack";
import { useFocusEffect } from "@react-navigation/native";
import React, { useCallback, useMemo, useState } from "react";
import {
  ActivityIndicator,
  FlatList,
  Pressable,
  StyleSheet,
  Text,
  View,
} from "react-native";
import { fetchProjects, GlossiaApiError } from "../api/glossia";
import { ProjectSummary } from "../api/types";
import { useAuth } from "../auth/AuthContext";
import { GlassBackground } from "../components/GlassBackground";
import { GlassSurface } from "../components/GlassSurface";
import { useBackendUrl } from "../dev/BackendUrlContext";
import { useI18n } from "../i18n/I18nContext";
import { RootStackParamList } from "../navigation/types";
import { appTheme } from "../theme/theme";

type Props = NativeStackScreenProps<RootStackParamList, "Account">;

export function AccountScreen({ route, navigation }: Props) {
  const { handle, type, visibility } = route.params;
  const { session } = useAuth();
  const { baseUrl } = useBackendUrl();
  const { t } = useI18n();

  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [projects, setProjects] = useState<ProjectSummary[]>([]);

  const accountTitle = useMemo(() => t("account_handle_display", { handle }), [handle, t]);
  const upcomingSections = useMemo(
    () => [t("section_overview"), t("section_issues"), t("section_glossary"), t("section_voice")],
    [t],
  );

  const loadProjects = useCallback(async () => {
    if (!session) {
      return;
    }

    setLoading(true);
    setError(null);

    try {
      const response = await fetchProjects({
        baseUrl,
        accessToken: session.accessToken,
        handle,
      });
      setProjects(response.projects || []);
    } catch (caughtError: unknown) {
      if (caughtError instanceof GlossiaApiError) {
        setError(caughtError.description);
      } else {
        setError(t("account_error_load_projects"));
      }
    } finally {
      setLoading(false);
    }
  }, [baseUrl, handle, session, t]);

  useFocusEffect(
    useCallback(() => {
      void loadProjects();
    }, [loadProjects]),
  );

  return (
    <View style={styles.container}>
      <GlassBackground />

      <GlassSurface style={styles.accountCard}>
        <Text style={styles.accountTitle}>{accountTitle}</Text>
        <Text style={styles.accountSubtitle}>{t("account_meta", { type, visibility })}</Text>
      </GlassSurface>

      <View style={styles.sectionHeader}>
        <Text style={styles.sectionTitle}>{t("account_projects_title")}</Text>
        <Text style={styles.sectionSubtitle}>{t("account_projects_subtitle")}</Text>
      </View>

      {loading ? (
        <View style={styles.center}>
          <GlassSurface style={styles.loadingCard}>
            <ActivityIndicator color={appTheme.colors.primary} />
          </GlassSurface>
        </View>
      ) : (
        <FlatList
          data={projects}
          keyExtractor={(project) => project.handle}
          contentContainerStyle={styles.listContent}
          ItemSeparatorComponent={() => <View style={styles.separator} />}
          renderItem={({ item }) => (
            <Pressable
              style={styles.projectPressable}
              onPress={() => {
                navigation.navigate("ProjectSections", {
                  accountHandle: handle,
                  projectHandle: item.handle,
                  projectName: item.name,
                });
              }}
            >
              <GlassSurface style={styles.projectCard}>
                <Text style={styles.projectName}>{item.name}</Text>
                <Text style={styles.projectHandle}>
                  {t("project_handle_display", { handle: item.handle })}
                </Text>
              </GlassSurface>
            </Pressable>
          )}
          ListEmptyComponent={
            <GlassSurface style={styles.emptyState}>
              <Text style={styles.emptyTitle}>{t("account_empty_projects_title")}</Text>
              <Text style={styles.emptyText}>{t("account_empty_projects_text")}</Text>
            </GlassSurface>
          }
          ListHeaderComponent={error ? <Text style={styles.errorText}>{error}</Text> : null}
        />
      )}

      <GlassSurface style={styles.upcomingCard}>
        <Text style={styles.upcomingTitle}>{t("account_upcoming_title")}</Text>
        <Text style={styles.upcomingText}>{t("account_upcoming_text")}</Text>
        <View style={styles.upcomingList}>
          {upcomingSections.map((section) => (
            <View key={section} style={styles.upcomingChip}>
              <Text style={styles.upcomingChipText}>{section}</Text>
            </View>
          ))}
        </View>
      </GlassSurface>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: appTheme.colors.bg,
    position: "relative",
  },
  accountCard: {
    margin: appTheme.spacing.x4,
    marginBottom: appTheme.spacing.x2,
    borderRadius: appTheme.radius.md,
    padding: appTheme.spacing.x4,
  },
  accountTitle: {
    color: appTheme.colors.text,
    fontSize: 24,
    fontWeight: "700",
  },
  accountSubtitle: {
    marginTop: appTheme.spacing.x1,
    color: appTheme.colors.textSecondary,
    fontSize: 14,
  },
  sectionHeader: {
    paddingHorizontal: appTheme.spacing.x4,
    paddingVertical: appTheme.spacing.x2,
  },
  sectionTitle: {
    color: appTheme.colors.text,
    fontSize: 18,
    fontWeight: "700",
  },
  sectionSubtitle: {
    marginTop: appTheme.spacing.x1,
    color: appTheme.colors.textMuted,
    fontSize: 13,
  },
  listContent: {
    paddingHorizontal: appTheme.spacing.x4,
    paddingBottom: appTheme.spacing.x4,
  },
  separator: {
    height: appTheme.spacing.x3,
  },
  projectPressable: {
    borderRadius: appTheme.radius.md,
  },
  projectCard: {
    borderRadius: appTheme.radius.md,
    padding: appTheme.spacing.x4,
  },
  projectName: {
    color: appTheme.colors.text,
    fontSize: 16,
    fontWeight: "600",
  },
  projectHandle: {
    marginTop: appTheme.spacing.x1,
    color: appTheme.colors.textSecondary,
    fontSize: 13,
  },
  center: {
    paddingVertical: appTheme.spacing.x8,
    alignItems: "center",
    justifyContent: "center",
  },
  loadingCard: {
    borderRadius: appTheme.radius.full,
    paddingHorizontal: appTheme.spacing.x5,
    paddingVertical: appTheme.spacing.x3,
  },
  errorText: {
    marginBottom: appTheme.spacing.x3,
    borderWidth: 1,
    borderColor: appTheme.colors.error,
    borderRadius: appTheme.radius.md,
    padding: appTheme.spacing.x3,
    color: appTheme.colors.error,
    backgroundColor: appTheme.colors.errorSoft,
  },
  emptyState: {
    borderRadius: appTheme.radius.md,
    padding: appTheme.spacing.x4,
    gap: appTheme.spacing.x2,
  },
  emptyTitle: {
    color: appTheme.colors.text,
    fontSize: 16,
    fontWeight: "700",
  },
  emptyText: {
    color: appTheme.colors.textSecondary,
    fontSize: 14,
  },
  upcomingCard: {
    margin: appTheme.spacing.x4,
    marginTop: 0,
    borderRadius: appTheme.radius.md,
    padding: appTheme.spacing.x4,
    gap: appTheme.spacing.x2,
  },
  upcomingTitle: {
    color: appTheme.colors.text,
    fontSize: 16,
    fontWeight: "700",
  },
  upcomingText: {
    color: appTheme.colors.textSecondary,
    fontSize: 14,
  },
  upcomingList: {
    flexDirection: "row",
    flexWrap: "wrap",
    gap: appTheme.spacing.x2,
  },
  upcomingChip: {
    borderRadius: appTheme.radius.full,
    borderWidth: 1,
    borderColor: appTheme.colors.primaryMid,
    backgroundColor: appTheme.colors.primarySoft,
    paddingHorizontal: appTheme.spacing.x3,
    paddingVertical: appTheme.spacing.x1,
  },
  upcomingChipText: {
    color: appTheme.colors.primary,
    fontSize: 12,
    fontWeight: "600",
  },
});
