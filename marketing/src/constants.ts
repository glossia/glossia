export const siteTitle = "Glossia - Open Source Localization Operative System";
export const siteDescription =
  "Glossia is an open source localization operative system that leverages the power of LLMs to incrementally localize content from content sources like GitHub, GitLab, Shopify Stores, Apps, and Themes, Figma designs, and more.";

export function siteURL() {
  if (import.meta.env.PROD) {
    return new URL(import.meta.env.SITE);
  } else {
    return new URL("http://localhost:4321/");
  }
}
