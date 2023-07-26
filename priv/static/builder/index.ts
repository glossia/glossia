import { createAppsignalClient } from "https://deno.land/x/appsignal@v1.0.1/mod.ts";
import {
  getAppSignalAPIKey,
  getEvent,
  getGitAccessToken,
  getGitRepositoryId,
  getGitRepositoryVCS,
} from "./environment.ts";
import { outputHeadingTableWithContext } from "./output.ts";
import { CleanOptions, simpleGit } from "simple-git";

let sendErrorReport: any = () => {};
const appSignalAPIKey = getAppSignalAPIKey();
if (appSignalAPIKey) {
  sendErrorReport = createAppsignalClient(appSignalAPIKey, "deno");
}

try {
  outputHeadingTableWithContext();
  if (getEvent() === "push") {
    const remoteURL =
      `https://${getGitAccessToken()}@${getGitRepositoryVCS()}.com/${getGitRepositoryId()}.git`;
    const tempDirPath = await Deno.makeTempDir();
    console.log(`Cloning ${remoteURL} into ${tempDirPath}`);
    await simpleGit()
      .clone(remoteURL, tempDirPath, {});
    console.log(`Successfully cloned`);
  }
} catch (err) {
  await sendErrorReport(err, {});
}
