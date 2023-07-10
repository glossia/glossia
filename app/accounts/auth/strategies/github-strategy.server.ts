import { GitHubStrategy } from "remix-auth-github";
import { getGitHubAppCallbackURL, getGitHubAppClientId, getGitHubAppClientSecret } from "~/lib/environment";
import type { CookieUser } from "../cookie-user";
import { findOrCreateUser } from "~/accounts/repositories/user-repository";

export const gitHubStrategy = new GitHubStrategy(
  {
    clientID: getGitHubAppClientId(),
    clientSecret: getGitHubAppClientSecret(),
    callbackURL: getGitHubAppCallbackURL().toString(),
  },
  async ({ accessToken, extraParams, profile }): Promise<CookieUser> => {
    const user = await findOrCreateUser({ email: profile.emails[0].value })
    console.log(user)
    return { email: user.email, id: user.id }
  }
);
