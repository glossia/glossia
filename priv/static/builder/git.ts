import { getGitAccessToken, getVCSId, getVCSPlatform } from "./environment.ts";

// https://github.blog/2020-12-21-get-up-to-speed-with-partial-clone-and-shallow-clone/
export async function cloneGitRepository(
  { into: directory }: { into: string },
) {
  const remoteURL =
    `https://${getGitAccessToken()}@${getVCSPlatform()}.com/${getVCSId()}.git`;
  console.log(`Cloning ${remoteURL}`);
  const cloneCommand = new Deno.Command("/usr/bin/env", {
    args: ["git", "clone", remoteURL, directory, "--filter=tree:0"],
  });
  await cloneCommand.output();
  console.log(`Repository cloned`);
}
