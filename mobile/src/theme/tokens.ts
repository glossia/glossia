/*
 * Semantic tokens mirrored from app/priv/static/assets/styles.css (:root semantic tokens).
 * Keep this file aligned with web theme changes.
 */

export const colors = {
  text: "#1c1917",
  textSecondary: "#3d3833",
  textMuted: "#5c564e",
  textOnAccent: "#ffffff",
  bg: "#faf8f5",
  bgSubtle: "#f2efe9",
  surface: "#ffffff",
  primary: "#6d3cc4",
  primaryHover: "#5b2dab",
  primarySoft: "rgba(109, 60, 196, 0.07)",
  primaryMid: "rgba(109, 60, 196, 0.13)",
  accent: "#f59e0b",
  accentSoft: "rgba(245, 158, 11, 0.1)",
  success: "#059669",
  successSoft: "rgba(5, 150, 105, 0.08)",
  border: "#e4e0d9",
  borderStrong: "#d1cdc5",
  error: "#dc2626",
  errorSoft: "rgba(220, 38, 38, 0.08)",
  glassSurface: "rgba(255, 255, 255, 0.58)",
  glassSurfaceStrong: "rgba(255, 255, 255, 0.74)",
  glassBorder: "rgba(255, 255, 255, 0.72)",
  glassBackdropTop: "rgba(109, 60, 196, 0.18)",
  glassBackdropBottom: "rgba(245, 158, 11, 0.16)",
  glassShadow: "#2f2352",
} as const;

export const spacing = {
  x0: 0,
  x1: 4,
  x2: 8,
  x3: 12,
  x4: 16,
  x5: 20,
  x6: 24,
  x8: 32,
  x10: 40,
  x12: 48,
  x16: 64,
} as const;

export const radius = {
  xs: 4,
  sm: 6,
  md: 8,
  lg: 12,
  full: 999,
} as const;
