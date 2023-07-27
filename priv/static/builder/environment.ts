export function getAppSignalAPIKey() {
  return Deno.env.get("GLOSSIA_APP_SIGNAL_API_KEY");
}

export function getBuildId() {
  return Deno.env.get("GLOSSIA_BUILD_ID");
}

export function getEvent() {
  return Deno.env.get("GLOSSIA_EVENT");
}

export function getGitAccessToken() {
  return Deno.env.get("GLOSSIA_GIT_ACCESS_TOKEN");
}

export function getGitRepositoryId() {
  return Deno.env.get("GLOSSIA_GIT_REPOSITORY_ID");
}

export function getGitRepositoryVersionControl() {
  return Deno.env.get("GLOSSIA_GIT_REPOSITORY_VersionControl");
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
