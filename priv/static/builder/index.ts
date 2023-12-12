import { getBuildType } from "./utils/environment.ts";
import { outputHeadingTableWithContext } from "./utils/output.ts";
import { runReportingErrors } from "./utils/errors.ts";

await runReportingErrors(async () => {
  outputHeadingTableWithContext();
  const process = (await import(`./events/${getBuildType()}.ts`)).default;
  await process();
});
