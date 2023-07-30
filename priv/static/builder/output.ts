import AsciiTable from "https://deno.land/x/ascii_table/mod.ts";
import {
  getAppSignalAPIKey,
  getEvent,
  getGitAccessToken,
  getGitCommitSHA,
  getGitDefaultBranch,
  getGitEventID,
  getGitRef,
  getVCSId,
  getVCSPlatform,
} from "./environment.ts";

export function outputHeadingTableWithContext() {
  const table = new AsciiTable("Build information");
  table
    .addRow("Git event ID", getGitEventID())
    .addRow("Event", getEvent())
    .addRow("Git access token", getGitAccessToken())
    .addRow("App Signal API key", getAppSignalAPIKey())
    .addRow("VCS Platform", getVCSPlatform())
    .addRow("VCS ID", getVCSId())
    .addRow("Git commit SHA", getGitCommitSHA())
    .addRow("Git ref", getGitRef())
    .addRow("Git default branch", getGitDefaultBranch());

  console.log(table.toString());
}
