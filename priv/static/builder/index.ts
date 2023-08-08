import { getEvent } from "./utils/environment.ts";
import { outputHeadingTableWithContext } from "./utils/output.ts";
import { runReportingErrors } from "./utils/errors.ts";

await runReportingErrors(async () => {
  outputHeadingTableWithContext();
  const process = (await import(`./events/${getEvent()}.ts`)).default;
  await process();
});
