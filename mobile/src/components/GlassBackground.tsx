import React from "react";
import { Platform, StyleSheet, View } from "react-native";
import { appTheme } from "../theme/theme";

export function GlassBackground() {
  if (Platform.OS !== "ios") {
    return null;
  }

  return (
    <View pointerEvents="none" style={styles.container}>
      <View style={[styles.orb, styles.topOrb]} />
      <View style={[styles.orb, styles.bottomOrb]} />
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    ...StyleSheet.absoluteFillObject,
  },
  orb: {
    position: "absolute",
    borderRadius: appTheme.radius.full,
  },
  topOrb: {
    width: 280,
    height: 280,
    top: -80,
    right: -80,
    backgroundColor: appTheme.colors.glassBackdropTop,
  },
  bottomOrb: {
    width: 260,
    height: 260,
    bottom: -90,
    left: -90,
    backgroundColor: appTheme.colors.glassBackdropBottom,
  },
});
