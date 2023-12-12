import {
  getContentSourcePlatform,
  getOwnerHandle,
  getProjectHandle,
} from "../utils/environment.ts";
import { cloneGitRepository } from "../utils/git.ts";
import { glossiaFetch } from "../utils/http.ts";
import { loadConfigurationManifests } from "../utils/vcs/configuration_loader.ts";
import { generateLocalizationPayload } from "../utils/vcs/localization.ts";

export default async function newVersion() {
  if (getContentSourcePlatform() === "github") {
    return await newGitHubContentVersion();
  }
}

async function newGitHubContentVersion() {
  const tempDirPath = await Deno.makeTempDir();
  await cloneGitRepository({ root: tempDirPath });
  console.info("Loading configuration manifests");
  const configurationManifests = await loadConfigurationManifests({
    root: tempDirPath,
  });
  console.info("Configuration manifests loaded", configurationManifests);
  console.info("Generating localization request payload");
  const payload = await generateLocalizationPayload(
    configurationManifests,
    {
      rootDirectory: tempDirPath,
      env: Deno.env,
    },
  );
  console.info(
    "Localization request payload generated",
    JSON.stringify(payload, null, 2),
  );
  console.info("Creating localization request");
  await glossiaFetch(
    `/api/v1/projects/${getOwnerHandle()}/${getProjectHandle()}/localizations`,
    {
      method: "POST",
      body: JSON.stringify(payload),
      headers: {
        "content-type": "application/json",
      },
    },
  );
  console.info("Localization request sent to the server");
}
