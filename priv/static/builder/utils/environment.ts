/**
 * It returns the API Key that should be used to authenticate requests against App Signal.
 * @param env {Deno.Env} An object containing the enviornment variables of the system.
 * @returns
 */
export function getAppSignalAPIKey(env: Deno.Env = Deno.env) {
  return env.get("GLOSSIA_APP_SIGNAL_API_KEY");
}

/**
 * It returns the unique identifier of the git event persisted in Glossia's database.
 * @param env {Deno.Env} An object containing the enviornment variables of the system.
 * @returns
 */
export function getGitEventID(env: Deno.Env = Deno.env) {
  return env.get("GLOSSIA_GIT_EVENT_ID");
}

type Event = "git_push";

/**
 * It returns the event that triggered the builder.
 * @param env {Deno.Env} An object containing the enviornment variables of the system.
 * @returns
 */
export function getEvent(env: Deno.Env = Deno.env): Event {
  const event = env.get("GLOSSIA_EVENT");
  switch (event) {
    case "git_push":
      return "git_push";
    default:
      throw new Error(
        `This instance of the builder doesn't support the event '${event}'`,
      );
  }
}

/**
 * It returns the URL of the Glossia HTTP server that the builder should interact with.
 * This is necessary to decouple the builder from a particular environment (e.g. production).
 * When run locally in a Docker build, the builder can communicate with the server running
 * in the host by accessing localhost.
 * @param env {Deno.Env} An object containing the enviornment variables of the system.
 * @returns
 */
export function getURL(env: Deno.Env = Deno.env) {
  return env.get("GLOSSIA_URL");
}

/**
 * It returns the access token that should be used to authenticate Git operations against
 * the Git platform (e.g. GitHub.)
 * @param env {Deno.Env} An object containing the enviornment variables of the system.
 * @returns
 */
export function getGitAccessToken(env: Deno.Env = Deno.env) {
  return env.get("GLOSSIA_GIT_ACCESS_TOKEN") ??
    env.get("GITHUB_TOKEN");
}

/**
 * It returns the access token that should be used to authenticate requests against Glossia.
 * @param env {Deno.Env} An object containing the enviornment variables of the system.
 * @returns
 */
export function getAccessToken(env: Deno.Env = Deno.env) {
  return env.get("GLOSSIA_ACCESS_TOKEN");
}

/**
 * It returns the identifier of the repository on the VCS platform. For example, GitHub
 * uses "organization/repository" as identifier.
 * @param env {Deno.Env} An object containing the enviornment variables of the system.
 * @returns
 */
export function getContentSourceId(env: Deno.Env = Deno.env) {
  return env.get("GLOSSIA_CONTENT_SOURCE_ID");
}

type VCSPlatform = "github";

/**
 * It returns the identifier of the VCS platform (e.g. github)
 * @param env {Deno.Env} An object containing the enviornment variables of the system.
 * @returns
 */
export function getContentSourcePlatform(
  env: Deno.Env = Deno.env,
): VCSPlatform | undefined {
  const platform = env.get("GLOSSIA_CONTENT_SOURCE_PLATFORM");
  if (!platform) return undefined;
  switch (platform) {
    case "github":
      return "github";
    default:
      throw new Error(
        `This instance of the builder doesn't support the VCS platform '${platform}'`,
      );
  }
}

/**
 * It returns the SHA of the commit that led to triggering this build.
 * This value is only present when the event is a git event.
 * @param env {Deno.Env} An object containing the enviornment variables of the system.
 * @returns
 */
export function getGitCommitSHA(env: Deno.Env = Deno.env) {
  return env.get("GLOSSIA_GIT_COMMIT_SHA");
}

/**
 * It returns the branch reference from the event that led to triggering this build.
 * This value is only present when the event is a git event.
 * @param env {Deno.Env} An object containing the enviornment variables of the system.
 * @returns
 */
export function getGitRef(env: Deno.Env = Deno.env) {
  return env.get("GLOSSIA_GIT_REF");
}

/**
 * It returns the owner handle from the event that led to triggering this build.
 * @param env {Deno.Env} An object containing the enviornment variables of the system.
 */
export function getOwnerHandle(env: Deno.Env = Deno.env) {
  return env.get("GLOSSIA_OWNER_HANDLE");
}

/**
 * It returns the project handle from the event that led to triggering this build.
 * @param env {Deno.Env} An object containing the enviornment variables of the system.
 */
export function getProjectHandle(env: Deno.Env = Deno.env) {
  return env.get("GLOSSIA_PROJECT_HANDLE");
}

/**
 * It returns the default branch from Git repository.
 * This value is only present when the event is a git event.
 * @param env {Deno.Env} An object containing the enviornment variables of the system.
 * @returns
 */
export function getGitDefaultBranch(env: Deno.Env = Deno.env) {
  return env.get("GLOSSIA_GIT_DEFAULT_BRANCH");
}

type Environment = "production" | "development";

/**
 * It returns the environment in which the builder is running.
 * @param env {Deno.Env} An object containing the enviornment variables of the system.
 * @returns
 */
export function getEnvironment(
  env: Deno.Env = Deno.env,
): Environment {
  return env.get("GLOSSIA_ENV") === "production" ? "production" : "development";
}
