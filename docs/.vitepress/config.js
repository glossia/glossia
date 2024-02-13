import { defineConfig } from "vitepress";

// https://vitepress.dev/reference/site-config
export default defineConfig({
  base: "/docs",
  outDir: ".vitepress/dist/docs",
  title: "Glossia Documentation",
  description:
    "In these pages you'll find documentation for users and contributors.",
  themeConfig: {
    // https://vitepress.dev/reference/default-theme-config
    nav: [
      { text: "Home", link: "/" },
      { text: "GitHub", link: "https://github.com/glossia" },
    ],

    sidebar: [
      {
        text: "Glossia",
        items: [
          { text: "What is Glossia", link: "/index" },
        ],
      },
    ],

    socialLinks: [
      { icon: "github", link: "https://github.com/glossia/glossia" },
      { icon: "x", link: "https://x.com/glossiaai" },
    ],
  },
});
