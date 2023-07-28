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
  const cloneProcess = await cloneCommand.spawn();
  if (!(await cloneProcess.status).success) {
    throw new Error("Failed to clone repository");
  }
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
  console.log(`Repository cloned`);
}

export async function installGitIfNeeded() {
  // Install
  const installCommand = new Deno.Command("/usr/bin", {
    args: ["apk", "add", "git"],
    stdin: "null",
  });
  const installResult = await installCommand.spawn();
  if (!(await installResult.status).success) {
    throw new Error("Failed to install git");
  }

  // Configure name
  const configureNameCommand = new Deno.Command("/usr/bin", {
    args: ["git", "config", "--global", "user.name", "Glossia"],
    stdin: "null",
  });
  const configureNameResult = await configureNameCommand.spawn();
  if (!(await configureNameResult.status).success) {
    throw new Error("Failed to configure git name");
  }

  // Configure email
  const configureEmailCommand = new Deno.Command("/usr/bin", {
    args: ["git", "config", "--global", "user.email", "github@glossia.ai"],
    stdin: "null",
  });
  const configureEmailResult = await configureEmailCommand.spawn();
  if (!(await configureEmailResult.status).success) {
    throw new Error("Failed to configure git email");
  }
}
