/**
 * Event writer for the setup agent.
 *
 * Dual output:
 * 1. Phoenix Channel (WebSocket real-time event streaming)
 * 2. JSONL file at /tmp/agent-events.jsonl (fallback / debugging)
 * 3. Status file at /tmp/agent-status.json (completion detection)
 */

import { Socket } from "npm:phoenix@1.8.3";

const EVENTS_PATH = "/tmp/agent-events.jsonl";
const STATUS_PATH = "/tmp/agent-status.json";

let sequence = 0;
// deno-lint-ignore no-explicit-any
let channel: any = null;
// deno-lint-ignore no-explicit-any
let socket: any = null;

export interface AgentEvent {
  type: string;
  content: string;
  _seq: number;
  _ts: string;
  [key: string]: unknown;
}

function writeStatus(status: string): void {
  Deno.writeTextFileSync(
    STATUS_PATH,
    JSON.stringify({ status, updated_at: new Date().toISOString() })
  );
}

/**
 * Initialize the event system. Connects to the Phoenix server via WebSocket
 * and joins the agent channel. Returns a promise that resolves when the
 * channel join succeeds.
 */
export function init(opts: {
  serverUrl: string;
  token: string;
  projectId: string;
}): Promise<void> {
  Deno.writeTextFileSync(EVENTS_PATH, "");
  writeStatus("running");

  return new Promise<void>((resolve, reject) => {
    const wsUrl = opts.serverUrl
      .replace(/^http:/, "ws:")
      .replace(/^https:/, "wss:");

    socket = new Socket(`${wsUrl}/agent/socket`, {
      params: { token: opts.token },
      reconnectAfterMs: (tries: number) =>
        [1000, 2000, 5000, 10000][tries - 1] || 10000,
    });

    socket.connect();

    channel = socket.channel(`agent:setup:${opts.projectId}`, {});

    channel
      .join()
      .receive("ok", () => {
        resolve();
      })
      .receive("error", (resp: Record<string, unknown>) => {
        reject(new Error(`Failed to join channel: ${JSON.stringify(resp)}`));
      })
      .receive("timeout", () => {
        reject(new Error("Channel join timed out"));
      });
  });
}

export function emit(
  type: string,
  content: string,
  extra: Record<string, unknown> = {}
): void {
  const event: AgentEvent = {
    ...extra,
    type,
    content,
    _seq: sequence++,
    _ts: new Date().toISOString(),
  };

  // Write to JSONL file (fallback/debugging)
  Deno.writeTextFileSync(EVENTS_PATH, JSON.stringify(event) + "\n", {
    append: true,
  });

  // Push via Phoenix Channel (real-time)
  if (channel) {
    channel.push("event", {
      sequence: event._seq,
      event_type: event.type,
      content: event.content,
      metadata: JSON.stringify(
        Object.fromEntries(
          Object.entries(event).filter(
            ([k]) => !["type", "content", "_seq", "_ts"].includes(k)
          )
        )
      ),
    });
  }
}

export function complete(): void {
  writeStatus("completed");
  try {
    if (channel) channel.leave();
    if (socket) socket.disconnect();
  } catch {
    // Connection already closed
  }
}

export function fail(reason: string): void {
  emit("error", reason);
  writeStatus("failed");
  try {
    if (channel) channel.leave();
    if (socket) socket.disconnect();
  } catch {
    // Connection already closed
  }
}
