import { cloneGitRepository } from "../git.ts";

export async function processGitPush() {
  const tempDirPath = await Deno.makeTempDir();
  await cloneGitRepository({ into: tempDirPath });
}
