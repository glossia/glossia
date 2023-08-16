import { cloneGitRepository } from "../utils/git.ts";
import { glossiaFetch } from "../utils/http.ts";
import { loadConfigurationManifests } from "../utils/vcs/configuration_loader.ts";
import { generateTranslationPayload } from "../utils/vcs/translate-payload.ts";

export default async function gitPush() {
  const tempDirPath = await Deno.makeTempDir();
  await cloneGitRepository({ root: tempDirPath });
  console.info("Loading configuration manifests");
  const configurationManifests = await loadConfigurationManifests({
    root: tempDirPath,
  });
  console.info("Generating translation payload");
  const payload = await generateTranslationPayload(configurationManifests, {
    root: tempDirPath,
  });
  console.info("Creating translation");
  await glossiaFetch("/builder/api/translations", {
    method: "POST",
    body: JSON.stringify(payload),
    headers: {
      "content-type": "application/json",
    },
  });
  console.info("Translation delegated to the server");
}
