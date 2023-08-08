import { generateTranslationPayload } from "../utils/vcs.ts";
import { cloneGitRepository } from "../utils/git.ts";

export default async function gitPush() {
  const tempDirPath = await Deno.makeTempDir();
  await cloneGitRepository({ root: tempDirPath });
  const translationPayload = await generateTranslationPayload({
    root: tempDirPath,
  });
  console.log(translationPayload);
}
