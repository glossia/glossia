import AsciiTable from "https://deno.land/x/ascii_table/mod.ts";
import {
  getAppSignalAPIKey,
  getBuildId,
  getEvent,
  getGitAccessToken,
} from "./environment.ts";

export function outputHeadingTableWithContext() {
  const table = new AsciiTable("Build information");
  table
    .addRow("Build ID", getBuildId())
    .addRow("Event", getEvent())
    .addRow("Git access token", getGitAccessToken())
    .addRow("App Signal API key", getAppSignalAPIKey());

  console.log(table.toString());
}
