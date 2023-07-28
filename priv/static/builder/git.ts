import {
  getGitAccessToken,
  getGitCommitSHA,
  getVCSId,
  getVCSPlatform,
} from "./environment.ts";

// https://github.blog/2020-12-21-get-up-to-speed-with-partial-clone-and-shallow-clone/
export async function cloneGitRepository(
  { root }: { root: string },
) {
  clone({
    root: root,
    gitCommitSHA: getGitCommitSHA()!,
    gitAccessToken: getGitAccessToken()!,
    vcsPlatform: getVCSPlatform()!,
    vcsId: getVCSId()!,
  });
}

export async function clone(
  { root, gitAccessToken, vcsPlatform, vcsId, gitCommitSHA }: {
    root: string;
    gitCommitSHA: string;
    gitAccessToken: string | undefined;
    vcsPlatform: string;
    vcsId: string;
  },
) {
  const remoteURL = gitAccessToken
    ? `https://${getGitAccessToken()}@${vcsPlatform}.com/${vcsId}.git`
    : `https://${vcsPlatform}.com/${vcsId}.git`;
  console.log(`Cloning ${remoteURL}`);
  const cloneArgs = ["git", "clone", remoteURL, root, "--filter=tree:0"];
  console.log("Running:", cloneArgs.join(" "));
  const cloneCommand = new Deno.Command("/usr/bin/env", {
    args: cloneArgs,
    stdin: "null",
  });
  await cloneCommand.spawn();
  const checkoutArgs = ["git", "checkout", gitCommitSHA];
  console.log("Running:", checkoutArgs.join(" "));
  const checkoutCommand = new Deno.Command("/usr/bin/env", {
    args: checkoutArgs,
    cwd: root,
    stdin: "null",
  });
  await checkoutCommand.spawn();
  console.log(`Repository cloned`);
}
