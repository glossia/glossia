import { defineConfig } from "vitepress";

// https://vitepress.dev/reference/site-config
export default defineConfig({
  srcDir: "./content",
  title: "Glossia",
  description: "Glossia's documentation",
  themeConfig: {
    // https://vitepress.dev/reference/default-theme-config
    nav: [
      // { text: "Home", link: "/" },
      // { text: "Examples", link: "/markdown-examples" },
    ],

    sidebar: [
      {
        text: "Glossia",
        items: [
          { text: "Get Started", link: "/glossia/get-started" },
        ],
      },
      {
        text: "Content Sources",
        items: [
          { text: "GitHub", link: "/content-sources/github" },
        ],
      },
    ],

    socialLinks: [
      { icon: "github", link: "https://github.com/vuejs/vitepress" },
    ],
  },
});
