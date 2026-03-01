import { BlurView } from "expo-blur";
import React, { PropsWithChildren } from "react";
import { Platform, StyleProp, StyleSheet, View, ViewStyle } from "react-native";
import { appTheme } from "../theme/theme";

type GlassSurfaceProps = PropsWithChildren<{
  style?: StyleProp<ViewStyle>;
  intensity?: number;
}>;

const IOS_GLASS = Platform.OS === "ios";

export function GlassSurface({ children, style, intensity = 32 }: GlassSurfaceProps) {
  if (IOS_GLASS) {
    return (
      <BlurView tint="light" intensity={intensity} style={[styles.base, styles.ios, style]}>
        {children}
      </BlurView>
    );
  }

  return <View style={[styles.base, styles.fallback, style]}>{children}</View>;
}

const styles = StyleSheet.create({
  base: {
    overflow: "hidden",
    borderWidth: StyleSheet.hairlineWidth,
    borderColor: appTheme.colors.glassBorder,
    backgroundColor: appTheme.colors.glassSurface,
  },
  ios: {
    shadowColor: appTheme.colors.glassShadow,
    shadowOpacity: 0.18,
    shadowRadius: 16,
    shadowOffset: {
      width: 0,
      height: 10,
    },
  },
  fallback: {
    borderColor: appTheme.colors.border,
    backgroundColor: appTheme.colors.surface,
  },
});
