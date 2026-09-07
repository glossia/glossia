import { DefaultTheme, Theme } from "@react-navigation/native";
import { colors, radius, spacing } from "./tokens";

export const appTheme = {
  colors,
  spacing,
  radius,
} as const;

export const navigationTheme: Theme = {
  ...DefaultTheme,
  dark: false,
  colors: {
    ...DefaultTheme.colors,
    primary: colors.primary,
    background: colors.bg,
    card: colors.surface,
    text: colors.text,
    border: colors.border,
    notification: colors.accent,
  },
};
