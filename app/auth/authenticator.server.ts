import { Authenticator } from "remix-auth";
import { sessionStorage } from "./session-storage.server.js";
import type { CookieUser } from "./cookie-user.js";
import { gitHubStrategy } from "./strategies/github-strategy.server.js";

let authenticator = new Authenticator<CookieUser>(sessionStorage);
authenticator.use(gitHubStrategy)

export { authenticator }
