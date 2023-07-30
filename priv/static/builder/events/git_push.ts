import { generateTranslationPayload } from "../vcs.ts";
import { cloneGitRepository } from "../git.ts";

export async function processGitPush() {
  const tempDirPath = await Deno.makeTempDir();
  await cloneGitRepository({ root: tempDirPath });
  const translationPayload = await generateTranslationPayload({
    root: tempDirPath,
  });
  console.log(translationPayload);
}
