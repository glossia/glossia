import { defineConfig } from "vitepress";

// https://vitepress.dev/reference/site-config
export default defineConfig({
  base: "/handbook",
  outDir: ".vitepress/dist/handbook",
  title: "Glossia Handbook",
  description:
    "In these pages you'll find the blueprint for the Glossia project.",
  themeConfig: {
    logo: "/logo.svg",
    // https://vitepress.dev/reference/default-theme-config
    nav: [
      { text: "Home", link: "/" },
    ],

    sidebar: [
      {
        text: "Company",
        items: [
          { text: "Who are we", link: "/index" },
        ],
      },
    ],

    socialLinks: [
      { icon: "github", link: "https://github.com/vuejs/vitepress" },
    ],
  },
});
