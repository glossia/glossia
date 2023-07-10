import { GitHubStrategy } from "remix-auth-github";

export const gitHubStrategy = new GitHubStrategy(
  {
    clientID: "YOUR_CLIENT_ID",
    clientSecret: "YOUR_CLIENT_SECRET",
    callbackURL: "https://example.com/auth/github/callback",
  },
  async ({ accessToken, extraParams, profile }) => {
    // Get the user data from your DB or API using the tokens and profile
    // TODO
    return User.findOrCreate({ email: profile.emails[0].value });
  }
);
