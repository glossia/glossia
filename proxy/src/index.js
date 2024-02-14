export default {
  async fetch(request) {
    const path = new URL(request.url).pathname;
    if (path.startsWith("/docs")) {
      const baseURL = `https://glossia-documentation.pages.dev`;
      return fetch(baseURL + path, request);
    } else {
      const baseURL = `https://glossia.fly.dev`;
      return fetch(baseURL + path, request);
    }
  },
};
