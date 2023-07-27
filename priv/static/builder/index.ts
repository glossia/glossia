import { createAppsignalClient } from "https://deno.land/x/appsignal@v1.0.1/mod.ts";
import {
  getAppSignalAPIKey,
  getEvent,
  getGitAccessToken,
  getGitRepositoryId,
  getGitRepositoryVCS,
} from "./environment.ts";
import { outputHeadingTableWithContext } from "./output.ts";
const { simpleGit } = await import("npm:simple-git@~3.19.1");

let sendErrorReport: any = () => {};
const appSignalAPIKey = getAppSignalAPIKey();
if (appSignalAPIKey) {
  sendErrorReport = createAppsignalClient(appSignalAPIKey, "deno");
}

try {
  outputHeadingTableWithContext();
  if (getEvent() === "push") {
    // https://github.blog/2020-12-21-get-up-to-speed-with-partial-clone-and-shallow-clone/
    const remoteURL =
      `https://${getGitAccessToken()}@${getGitRepositoryVCS()}.com/${getGitRepositoryId()}.git`;
    const tempDirPath = await Deno.makeTempDir();
    console.log(`Cloning ${remoteURL} into ${tempDirPath}`);
    await simpleGit()
      .clone(remoteURL, tempDirPath, { "--filter": "tree:0" });
    console.log(`Successfully cloned`);
  }
} catch (err) {
  await sendErrorReport(err, {});
}
