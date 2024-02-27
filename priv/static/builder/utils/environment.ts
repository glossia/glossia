/**
 * It returns the API Key that should be used to authenticate requests against App Signal.
 * @param env {Deno.Env} An object containing the enviornment variables of the system.
 * @returns
 */
export function getAppSignalAPIKey(env: Deno.Env = Deno.env) {
  return env.get("GLOSSIA_APP_SIGNAL_API_KEY");
}

/**
 * It returns the unique identifier of the event persisted in Glossia's database.
 * @param env {Deno.Env} An object containing the enviornment variables of the system.
 * @returns
 */
export function getBuildId(env: Deno.Env = Deno.env) {
  return env.get("GLOSSIA_BUILD_ID");
}

type Event = "new_version";

/**
 * It returns the event that triggered the builder.
 * @param env {Deno.Env} An object containing the enviornment variables of the system.
 * @returns
 */
export function getBuildType(env: Deno.Env = Deno.env): Event {
  const event = env.get("GLOSSIA_BUILD_TYPE");
  switch (event) {
    case "new_version":
      return "new_version";
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
 * It returns the access token that should be used to authenticate operations against the content source.
 * @param env {Deno.Env} An object containing the enviornment variables of the system.
 * @returns
 */
export function getContentSourceAccessToken(env: Deno.Env = Deno.env) {
  return env.get("GLOSSIA_CONTENT_SOURCE_ACCESS_TOKEN") ??
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
export function getIDInContentSourcePlatform(env: Deno.Env = Deno.env) {
  return env.get("GLOSSIA_id_in_platform");
}

type ContentSourcePlatform = "github";

/**
 * It returns the identifier of the VCS platform (e.g. github)
 * @param env {Deno.Env} An object containing the enviornment variables of the system.
 * @returns
 */
export function getContentSourcePlatform(
  env: Deno.Env = Deno.env,
): ContentSourcePlatform | undefined {
  const platform = env.get("GLOSSIA_platform");
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
 * It returns the content version associated to the event.
 * @param env {Deno.Env} An object containing the enviornment variables of the system.
 * @returns
 */
export function getBuildVersion(env: Deno.Env = Deno.env) {
  return env.get("GLOSSIA_BUILD_VERSION");
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
