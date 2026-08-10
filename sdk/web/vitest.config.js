import { defineConfig } from "vitest/config";

// The SDK touches `window`, `document`, `navigator`, `sessionStorage`, and
// `crypto` at module load, so every test needs a real DOM. `jsdom` provides
// one without pulling in a full headless browser.
export default defineConfig({
  test: {
    environment: "jsdom",
    include: ["src/**/*.test.js"],
  },
});
