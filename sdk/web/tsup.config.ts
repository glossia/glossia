import { defineConfig } from "tsup";

export default defineConfig({
  entry: ["src/index.ts"],
  format: ["esm", "cjs", "iife"],
  globalName: "glossia",
  dts: true,
  clean: true,
  sourcemap: false,
  target: "es2020",
});
