export default {
  async fetch(request) {
    const path = new URL(request.url).pathname;
    const isAuthenticationPath = path.startsWith("/auth");
    const isAuthorized = request.headers.has("authorization");

    if (path.startsWith("/docs")) {
      const baseURL = `https://glossia-documentation.pages.dev`;
      return fetch(baseURL + path, request);
    } else if (path.startsWith("/handbook")) {
      const baseURL = `https://glossia-handbook.pages.dev`;
      return fetch(baseURL + path, request);
    } else if (isAuthenticationPath || isAuthorized) {
      const baseURL = `https://glossia.fly.dev`;
      return fetch(baseURL + path, request);
    } else {
      const baseURL = `https://glossia.fly.dev`;
      return fetch(baseURL + path, request);
    }
  },
};
