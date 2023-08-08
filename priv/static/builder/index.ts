import { getEvent } from "./utils/environment.ts";
import { processGitPush } from "./events/git_push.ts";
import { outputHeadingTableWithContext } from "./output.ts";

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
