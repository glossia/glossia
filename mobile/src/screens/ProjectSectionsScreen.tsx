import { NativeStackScreenProps } from "@react-navigation/native-stack";
import React, { useMemo } from "react";
import { StyleSheet, Text, View } from "react-native";
import { GlassBackground } from "../components/GlassBackground";
import { GlassSurface } from "../components/GlassSurface";
import { useI18n } from "../i18n/I18nContext";
import { RootStackParamList } from "../navigation/types";
import { appTheme } from "../theme/theme";

type Props = NativeStackScreenProps<RootStackParamList, "ProjectSections">;

export function ProjectSectionsScreen({ route }: Props) {
  const { accountHandle, projectHandle, projectName } = route.params;
  const { t } = useI18n();

  const sections = useMemo(
    () => [
      { id: "overview", name: t("section_overview") },
      { id: "issues", name: t("section_issues") },
      { id: "voice", name: t("section_voice") },
      { id: "glossary", name: t("section_glossary") },
    ],
    [t],
  );

  return (
    <View style={styles.container}>
      <GlassBackground />

      <GlassSurface style={styles.hero}>
        <Text style={styles.title}>{projectName}</Text>
        <Text style={styles.subtitle}>{t("project_sections_path", { accountHandle, projectHandle })}</Text>
      </GlassSurface>

      <Text style={styles.label}>{t("project_sections_label")}</Text>

      <View style={styles.list}>
        {sections.map((section) => (
          <GlassSurface key={section.id} style={styles.row}>
            <Text style={styles.rowTitle}>{section.name}</Text>
            <Text style={styles.rowStatus}>{t("common_soon")}</Text>
          </GlassSurface>
        ))}
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: appTheme.colors.bg,
    padding: appTheme.spacing.x4,
    gap: appTheme.spacing.x4,
    position: "relative",
  },
  hero: {
    borderRadius: appTheme.radius.md,
    padding: appTheme.spacing.x4,
  },
  title: {
    color: appTheme.colors.text,
    fontSize: 24,
    fontWeight: "700",
  },
  subtitle: {
    marginTop: appTheme.spacing.x1,
    color: appTheme.colors.textSecondary,
    fontSize: 14,
  },
  label: {
    color: appTheme.colors.textMuted,
    fontSize: 13,
    textTransform: "uppercase",
    letterSpacing: 0.6,
    fontWeight: "600",
  },
  list: {
    gap: appTheme.spacing.x2,
  },
  row: {
    borderRadius: appTheme.radius.md,
    paddingVertical: appTheme.spacing.x3,
    paddingHorizontal: appTheme.spacing.x4,
    flexDirection: "row",
    alignItems: "center",
    justifyContent: "space-between",
  },
  rowTitle: {
    color: appTheme.colors.text,
    fontSize: 16,
    fontWeight: "600",
  },
  rowStatus: {
    color: appTheme.colors.primary,
    fontSize: 13,
    fontWeight: "700",
  },
});
