import AsciiTable from "https://deno.land/x/ascii_table/mod.ts";
import {
  getAppSignalAPIKey,
  getBuildId,
  getEvent,
  getGitAccessToken,
  getGitCommitSHA,
  getGitRepositoryId,
  getGitRepositoryVCS,
} from "./environment.ts";

export function outputHeadingTableWithContext() {
  const table = new AsciiTable("Build information");
  table
    .addRow("Build ID", getBuildId())
    .addRow("Event", getEvent())
    .addRow("Git access token", getGitAccessToken())
    .addRow("App Signal API key", getAppSignalAPIKey())
    .addRow("Git repository", getGitRepositoryId())
    .addRow("Git repository VCS", getGitRepositoryVCS())
    .addRow("Git commit SHA", getGitCommitSHA());

  console.log(table.toString());
}
