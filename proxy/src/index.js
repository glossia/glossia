export default {
  async fetch(request) {
    const path = new URL(request.url).pathname;
    const isAuthenticationPath = path.startsWith("/auth");
    const cookieValue = request.headers.get("Cookie");
    const hasSession = cookieValue &&
      cookieValue.includes("_glossia_key");

    if (path.startsWith("/docs")) {
      const baseURL = `https://glossia-documentation.pages.dev`;
      return fetch(baseURL + path, request);
    } else if (path.startsWith("/handbook")) {
      const baseURL = `https://glossia-handbook.pages.dev`;
      return fetch(baseURL + path, request);
    } else if (isAuthenticationPath || hasSession) {
      const baseURL = `https://glossia.fly.dev`;
      return fetch(baseURL + path, request);
    } else {
      const baseURL = `https://glossia-marketing.pages.dev`;
      return fetch(baseURL + path, request);
    }
  },
};
