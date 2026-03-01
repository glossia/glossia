import { NavigationContainer } from "@react-navigation/native";
import { createNativeStackNavigator } from "@react-navigation/native-stack";
import React from "react";
import { ActivityIndicator, Platform, StyleSheet, Text, View } from "react-native";
import { useAuth } from "../auth/AuthContext";
import { GlassBackground } from "../components/GlassBackground";
import { GlassSurface } from "../components/GlassSurface";
import { useBackendUrl } from "../dev/BackendUrlContext";
import { useI18n } from "../i18n/I18nContext";
import { AccountScreen } from "../screens/AccountScreen";
import { AccountsScreen } from "../screens/AccountsScreen";
import { LoginScreen } from "../screens/LoginScreen";
import { ProjectSectionsScreen } from "../screens/ProjectSectionsScreen";
import { appTheme, navigationTheme } from "../theme/theme";
import { RootStackParamList } from "./types";

const Stack = createNativeStackNavigator<RootStackParamList>();

function BootScreen() {
  const { t } = useI18n();

  return (
    <View style={styles.bootContainer}>
      <GlassBackground />
      <GlassSurface style={styles.bootCard}>
        <ActivityIndicator color={appTheme.colors.primary} />
        <Text style={styles.bootText}>{t("app_loading_session")}</Text>
      </GlassSurface>
    </View>
  );
}

export function AppNavigator() {
  const { status } = useAuth();
  const { isReady } = useBackendUrl();
  const { t } = useI18n();

  if (!isReady || status === "loading") {
    return <BootScreen />;
  }

  const screenOptions = {
    headerTintColor: appTheme.colors.text,
    headerTitleStyle: { fontWeight: "700" as const },
    contentStyle: { backgroundColor: appTheme.colors.bg },
    ...(Platform.OS === "ios"
      ? {
          headerStyle: { backgroundColor: appTheme.colors.glassSurfaceStrong },
          headerShadowVisible: false,
        }
      : {
          headerStyle: { backgroundColor: appTheme.colors.surface },
        }),
  };

  return (
    <NavigationContainer theme={navigationTheme}>
      {status === "signed_out" ? (
        <Stack.Navigator screenOptions={screenOptions}>
          <Stack.Screen name="Login" component={LoginScreen} options={{ title: t("nav_title_sign_in") }} />
        </Stack.Navigator>
      ) : (
        <Stack.Navigator initialRouteName="Accounts" screenOptions={screenOptions}>
          <Stack.Screen
            name="Accounts"
            component={AccountsScreen}
            options={{ title: t("nav_title_accounts") }}
          />
          <Stack.Screen
            name="Account"
            component={AccountScreen}
            options={({ route }) => ({ title: route.params.handle })}
          />
          <Stack.Screen
            name="ProjectSections"
            component={ProjectSectionsScreen}
            options={({ route }) => ({ title: route.params.projectHandle })}
          />
        </Stack.Navigator>
      )}
    </NavigationContainer>
  );
}

const styles = StyleSheet.create({
  bootContainer: {
    flex: 1,
    alignItems: "center",
    justifyContent: "center",
    gap: appTheme.spacing.x2,
    backgroundColor: appTheme.colors.bg,
    position: "relative",
  },
  bootCard: {
    borderRadius: appTheme.radius.lg,
    paddingHorizontal: appTheme.spacing.x6,
    paddingVertical: appTheme.spacing.x5,
    alignItems: "center",
    gap: appTheme.spacing.x2,
  },
  bootText: {
    color: appTheme.colors.textSecondary,
    fontSize: 14,
  },
});
