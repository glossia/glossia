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
  getGitRepositoryVersionControl,
} from "./environment.ts";

export function outputHeadingTableWithContext() {
  const table = new AsciiTable("Build information");
  table
    .addRow("Build ID", getBuildId())
    .addRow("Event", getEvent())
    .addRow("Git access token", getGitAccessToken())
    .addRow("App Signal API key", getAppSignalAPIKey())
    .addRow("Git repository", getGitRepositoryId())
    .addRow("Git repository VersionControl", getGitRepositoryVersionControl())
    .addRow("Git commit SHA", getGitCommitSHA())
    .addRow("Git ref", getGitRef())
    .addRow("Git default branch", getGitDefaultBranch());

  console.log(table.toString());
}
