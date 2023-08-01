export function getAppSignalAPIKey() {
  return Deno.env.get("GLOSSIA_APP_SIGNAL_API_KEY");
}

export function getGitEventID() {
  return Deno.env.get("GLOSSIA_GIT_EVENT_ID");
}

export function getEvent() {
  return Deno.env.get("GLOSSIA_EVENT");
}

export function getGitAccessToken() {
  return Deno.env.get("GLOSSIA_GIT_ACCESS_TOKEN");
}

export function getAccessToken() {
  return Deno.env.get("GLOSSIA_ACCESS_TOKEN") ?? Deno.env.get("GITHUB_TOKEN");
}

export function getVCSId() {
  return Deno.env.get("GLOSSIA_VCS_ID");
}

export function getVCSPlatform() {
  return Deno.env.get("GLOSSIA_VCS_PLATFORM");
}

export function getGitCommitSHA() {
  return Deno.env.get("GLOSSIA_GIT_COMMIT_SHA");
}

export function getGitRef() {
  return Deno.env.get("GLOSSIA_GIT_REF");
}

export function getGitDefaultBranch() {
  return Deno.env.get("GLOSSIA_GIT_DEFAULT_BRANCH");
}

export function getEnvironment(): "production" | "development" {
  return Deno.env.get("GLOSSIA_ENV") === "production"
    ? "production"
    : "development";
}
