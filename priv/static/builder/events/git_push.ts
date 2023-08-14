import { generateTranslationPayload } from "../utils/vcs.ts";
import { cloneGitRepository } from "../utils/git.ts";
import { loadConfigurationManifests } from "../utils/vcs/configuration_loader.ts";

export default async function gitPush() {
  const tempDirPath = await Deno.makeTempDir();
  await cloneGitRepository({ root: tempDirPath });
  const configurationManifests = await loadConfigurationManifests({
    root: tempDirPath,
  });

  console.log(configurationManifests);
}
