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
