import AsciiTable from "https://deno.land/x/ascii_table/mod.ts";
import {
  getAccessToken,
  getAppSignalAPIKey,
  getContentSourceId,
  getContentSourcePlatform,
  getEvent,
  getGitAccessToken,
  getGitCommitSHA,
  getGitDefaultBranch,
  getGitEventID,
  getGitRef,
  getOwnerHandle,
  getProjectHandle,
  getURL,
} from "../utils/environment.ts";

/**
 * Outputs a table with build metadata at the top of the logs.
 * This table is useful for debugging purposes.
 */
export function outputHeadingTableWithContext() {
  const table = new AsciiTable("Build information");
  table
    .addRow("URL", getURL())
    .addRow("Owner", getOwnerHandle())
    .addRow("Project", getProjectHandle())
    .addRow("Access token", getAccessToken())
    .addRow("Git event ID", getGitEventID())
    .addRow("Event", getEvent())
    .addRow("App Signal API key", getAppSignalAPIKey())
    .addRow("Content Source Platform", getContentSourcePlatform())
    .addRow("Content Source ID", getContentSourceId())
    .addRow("Git access token", getGitAccessToken())
    .addRow("Git commit SHA", getGitCommitSHA())
    .addRow("Git ref", getGitRef())
    .addRow("Git default branch", getGitDefaultBranch());

  console.log(table.toString());
}
