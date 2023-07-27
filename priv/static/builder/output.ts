import AsciiTable from "https://deno.land/x/ascii_table/mod.ts";
import {
  getAppSignalAPIKey,
  getBuildId,
  getEvent,
  getGitAccessToken,
  getGitCommitSHA,
  getGitDefaultBranch,
  getGitRef,
  getGitRepositoryId,
  getSVNPlatform,
} from "./environment.ts";

export function outputHeadingTableWithContext() {
  const table = new AsciiTable("Build information");
  table
    .addRow("Build ID", getBuildId())
    .addRow("Event", getEvent())
    .addRow("Git access token", getGitAccessToken())
    .addRow("App Signal API key", getAppSignalAPIKey())
    .addRow("VCS Platform", getSVNPlatform())
    .addRow("Git repository", getGitRepositoryId())
    .addRow("Git commit SHA", getGitCommitSHA())
    .addRow("Git ref", getGitRef())
    .addRow("Git default branch", getGitDefaultBranch());

  console.log(table.toString());
}
