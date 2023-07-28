import { loadConfigurations } from "../configuration.ts";
import { cloneGitRepository } from "../git.ts";

export async function processGitPush() {
  const tempDirPath = await Deno.makeTempDir();
  await cloneGitRepository({ root: tempDirPath });
  const configurationFiles = await loadConfigurations({ root: tempDirPath });
  console.log(configurationFiles);
}
