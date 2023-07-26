import { createAppsignalClient } from "https://deno.land/x/appsignal@v1.0.1/mod.ts";
import { getAppSignalAPIKey } from "./environment.ts";
import { outputHeadingTableWithContext } from "./output.ts";

let sendErrorReport: any = () => {};
const appSignalAPIKey = getAppSignalAPIKey();
if (appSignalAPIKey) {
  sendErrorReport = createAppsignalClient(appSignalAPIKey, "deno");
}

try {
  outputHeadingTableWithContext();
} catch (err) {
  await sendErrorReport(err, {});
}
