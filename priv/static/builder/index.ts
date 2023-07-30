import { createAppsignalClient } from "https://deno.land/x/appsignal@v1.0.1/mod.ts";
import { getAppSignalAPIKey, getEvent } from "./environment.ts";
import { processGitPush } from "./events/git_push.ts";
import { outputHeadingTableWithContext } from "./output.ts";

let sendErrorReport = () => {};
const appSignalAPIKey = getAppSignalAPIKey();
if (appSignalAPIKey) {
  // deno-lint-ignore ban-ts-comment
  // @ts-ignore
  sendErrorReport = createAppsignalClient(appSignalAPIKey, "deno");
}

try {
  outputHeadingTableWithContext();
  if (getEvent() === "git_push") {
    await processGitPush();
  } else {
    console.info(`No event handler for ${getEvent()}`);
  }
} catch (err) {
  console.error(err);
  // deno-lint-ignore ban-ts-comment
  // @ts-ignore
  await sendErrorReport(err, {});
}
