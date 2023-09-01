import AsciiTable from "https://deno.land/x/ascii_table/mod.ts";
import {
  getAccessToken,
  getAppSignalAPIKey,
  getContentSourceAccessToken,
  getContentSourceId,
  getContentSourcePlatform,
  getEventId,
  getEventType,
  getEventVersion,
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
    .addRow("Event ID", getEventId())
    .addRow("Event type", getEventType())
    .addRow("Event version", getEventVersion())
    .addRow("App Signal API key", getAppSignalAPIKey())
    .addRow("Content Source Platform", getContentSourcePlatform())
    .addRow("Content Source ID", getContentSourceId())
    .addRow("Content Soruce access token", getContentSourceAccessToken());

  console.log(table.toString());
}
