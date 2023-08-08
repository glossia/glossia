import { createAppsignalClient } from "https://deno.land/x/appsignal@v1.0.1/mod.ts";
import { getAppSignalAPIKey } from "./environment.ts";

export type RunReportingErrorsOptions = {
  reportFunction: ReturnType<typeof getReportFunction>;
};

/**
 * It runs and awaits the given function and reports the errors when it throws.
 * @param cb {() => Promise<void>} The function to be executed.
 * @params reportFunction{() => }
 */
export async function runReportingErrors(
  cb: () => Promise<void>,
  { reportFunction }: RunReportingErrorsOptions = {
    reportFunction: getReportFunction(),
  },
) {
  try {
    await cb();
  } catch (err) {
    console.error(err);
    await reportFunction(err, {});
    throw err;
  }
}

/**
 * It returns the function to report errors to the error reporting platform.
 * @returns {(error: Error, metadata: any) => Promise<void>} The function to report errors.
 */
function getReportFunction() {
  // deno-lint-ignore no-explicit-any
  let sendErrorReport: (error: Error, metadata: any) => Promise<void> = async (
    _error,
    _metadata,
  ) => {};
  const appSignalAPIKey = getAppSignalAPIKey();
  if (appSignalAPIKey) {
    // deno-lint-ignore ban-ts-comment
    // @ts-ignore
    sendErrorReport = createAppsignalClient(appSignalAPIKey, "deno");
  }
  return sendErrorReport;
}
