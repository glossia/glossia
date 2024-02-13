import {
  getBuildVersion,
  getContentSourceAccessToken,
  getContentSourcePlatform,
  getIDInContentSourcePlatform,
} from "./environment.ts";

// https://github.blog/2020-12-21-get-up-to-speed-with-partial-clone-and-shallow-clone/
export async function cloneGitRepository(
  { root }: { root: string },
) {
  await clone({
    root: root,
    gitCommitSHA: getBuildVersion()!,
    gitAccessToken: getContentSourceAccessToken()!,
    contentSourcePlatform: getContentSourcePlatform()!,
    idInContentSourcePlatform: getIDInContentSourcePlatform()!,
  });
}

export async function clone(
  {
    root,
    gitAccessToken,
    contentSourcePlatform,
    idInContentSourcePlatform,
    gitCommitSHA,
  }: {
    root: string;
    gitCommitSHA: string | undefined;
    gitAccessToken: string | undefined;
    contentSourcePlatform: string;
    idInContentSourcePlatform: string;
  },
) {
  const remoteURL = gitAccessToken
    ? `https://x-access-token:${gitAccessToken}@${contentSourcePlatform}.com/${idInContentSourcePlatform}.git`
    : `https://${contentSourcePlatform}.com/${idInContentSourcePlatform}.git`;
  console.log(`Cloning ${remoteURL}`);
  const cloneArgs = ["git", "clone", remoteURL, root, "--filter=tree:0"];
  console.log("Running:", cloneArgs.join(" "));
  const cloneCommand = new Deno.Command("/usr/bin/env", {
    args: cloneArgs,
    stdin: "null",
  });
  const cloneProcess = await cloneCommand.spawn();
  if (!(await cloneProcess.status).success) {
    throw new Error("Failed to clone repository");
  }
  if (gitCommitSHA) {
    const checkoutArgs = ["git", "checkout", gitCommitSHA];
    console.log("Running:", checkoutArgs.join(" "));
    const checkoutCommand = new Deno.Command("/usr/bin/env", {
      args: checkoutArgs,
      cwd: root,
      stdin: "null",
    });
    const checkoutProcess = await checkoutCommand.spawn();
    if (!(await checkoutProcess.status).success) {
      throw new Error("Failed to checkout the commit");
    }
  }

  console.log(`Repository cloned`);
}
