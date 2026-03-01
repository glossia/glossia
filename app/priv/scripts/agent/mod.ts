/**
 * Glossia setup agent.
 *
 * Runs inside a sandbox via Deno. Clones the repository, installs OpenCode,
 * configures the MiniMax provider, then drives OpenCode via the Agent Client
 * Protocol (ACP) over stdio. All events are bridged to the Phoenix server
 * via WebSocket channel.
 *
 * Usage:
 *   deno run --allow-all <url>/agent/scripts/mod.ts \
 *     --server-url=<url> --token=<token> --project-id=<id> \
 *     --config-path=/tmp/glossia-setup.json
 */

import { init, emit, complete, fail } from "./events.ts";

// ---------------------------------------------------------------------------
// Types
// ---------------------------------------------------------------------------

interface SetupConfig {
  github_repo_full_name: string;
  github_repo_default_branch: string;
  github_token: string | null;
  repo_path: string;
  target_languages: string[];
  minimax_api_key: string;
  model: string;
}

interface JsonRpcRequest {
  jsonrpc: "2.0";
  id: number;
  method: string;
  params: Record<string, unknown>;
}

interface JsonRpcNotification {
  jsonrpc: "2.0";
  method: string;
  params: Record<string, unknown>;
}

interface JsonRpcResponse {
  jsonrpc: "2.0";
  id: number;
  result?: Record<string, unknown>;
  error?: { code: number; message: string; data?: unknown };
}

type JsonRpcMessage = JsonRpcRequest | JsonRpcNotification | JsonRpcResponse;

// ---------------------------------------------------------------------------
// Argument parsing
// ---------------------------------------------------------------------------

function parseArgs(): {
  serverUrl: string;
  token: string;
  projectId: string;
  configPath: string;
} {
  const args: Record<string, string> = {};
  for (const arg of Deno.args) {
    const match = arg.match(/^--([a-z-]+)=(.+)$/);
    if (match) {
      args[match[1]] = match[2];
    }
  }

  const serverUrl = args["server-url"];
  const token = args["token"];
  const projectId = args["project-id"];
  const configPath = args["config-path"] || "/tmp/glossia-setup.json";

  if (!serverUrl || !token || !projectId) {
    console.error("Required args: --server-url, --token, --project-id");
    Deno.exit(1);
  }

  return { serverUrl, token, projectId, configPath };
}

// ---------------------------------------------------------------------------
// Config
// ---------------------------------------------------------------------------

async function readConfig(path: string): Promise<SetupConfig> {
  const text = await Deno.readTextFile(path);
  return JSON.parse(text) as SetupConfig;
}

// ---------------------------------------------------------------------------
// Shell execution helper
// ---------------------------------------------------------------------------

async function exec(
  cmd: string[],
  opts?: { env?: Record<string, string>; cwd?: string }
): Promise<{ code: number; stdout: string; stderr: string }> {
  const [bin, ...args] = cmd;
  const process = new Deno.Command(bin, {
    args,
    stdout: "piped",
    stderr: "piped",
    env: opts?.env,
    cwd: opts?.cwd,
  });

  const output = await process.output();
  const decoder = new TextDecoder();

  return {
    code: output.code,
    stdout: decoder.decode(output.stdout),
    stderr: decoder.decode(output.stderr),
  };
}

// ---------------------------------------------------------------------------
// Repository cloning
// ---------------------------------------------------------------------------

async function cloneRepo(config: SetupConfig): Promise<void> {
  emit("status", "Preparing repository...");

  const cloneUrl = config.github_token
    ? `https://x-access-token:${config.github_token}@github.com/${config.github_repo_full_name}.git`
    : `https://github.com/${config.github_repo_full_name}.git`;

  const result = await exec(["git", "clone", cloneUrl, config.repo_path]);
  if (result.code !== 0) {
    throw new Error(
      `Failed to clone repository (exit ${result.code}): ${result.stderr}`
    );
  }
}

// ---------------------------------------------------------------------------
// OpenCode installation and configuration
// ---------------------------------------------------------------------------

async function installOpenCode(): Promise<void> {
  const result = await exec(["npm", "install", "-g", "opencode-ai"]);
  if (result.code !== 0) {
    throw new Error(
      `Failed to install OpenCode (exit ${result.code}): ${result.stderr}`
    );
  }
}

async function writeOpenCodeConfig(config: SetupConfig): Promise<void> {
  const opencodeConfig = {
    $schema: "https://opencode.ai/config.json",
    provider: {
      minimax: {
        npm: "@ai-sdk/anthropic",
        options: {
          baseURL: "https://api.minimax.io/anthropic/v1",
          apiKey: config.minimax_api_key,
        },
        models: {
          "MiniMax-M2.5": {
            name: "MiniMax-M2.5",
            limit: {
              context: 200000,
              output: 131072,
            },
          },
        },
      },
    },
  };

  await Deno.writeTextFile(
    `${config.repo_path}/opencode.json`,
    JSON.stringify(opencodeConfig, null, 2)
  );
}

// ---------------------------------------------------------------------------
// Prompt
// ---------------------------------------------------------------------------

function buildPrompt(config: SetupConfig): string {
  const targets =
    config.target_languages && config.target_languages.length > 0
      ? config.target_languages.join(", ")
      : "infer from repository conventions";

  const targetInstruction =
    config.target_languages && config.target_languages.length > 0
      ? `Use exactly these targets: ${targets}.`
      : "Infer targets conservatively and keep the list minimal.";

  return [
    "Set up Glossia localization for this repository.",
    "",
    "Primary objective",
    "- Produce the minimum useful GLOSSIA.md so the resulting PR is a clean reference example.",
    "- Keep the file concise, practical, and easy to adapt.",
    "",
    "GLOSSIA.md structure (Glossia spec: /docs/reference/glossia-md)",
    "- GLOSSIA.md is the repository-level Glossia configuration file.",
    "- Include TOML frontmatter between +++ markers.",
    "- Add one or more [[content]] entries.",
    "- For translation entries, include source, targets, and output.",
    "- Add brief free-text context below frontmatter (product context + tone).",
    "",
    "Localization requirements",
    `- ${targetInstruction}`,
    "- Ensure the selected language preferences are reflected in targets.",
    "- Use output templates with {lang} and {relpath} for translated paths.",
    "",
    "Definition of done",
    `- Write exactly one file: ${config.repo_path}/GLOSSIA.md`,
    "- The result should be minimal but complete enough for reviewers to merge directly as a baseline.",
    "- Do not return extra narrative; focus on the file content.",
  ].join("\n");
}

// ---------------------------------------------------------------------------
// ACP Client
// ---------------------------------------------------------------------------

class AcpClient {
  private process: Deno.ChildProcess;
  private writer: WritableStreamDefaultWriter<Uint8Array>;
  private encoder = new TextEncoder();
  private decoder = new TextDecoder();
  private nextId = 1;
  private pendingRequests = new Map<
    number,
    {
      resolve: (result: Record<string, unknown>) => void;
      reject: (error: Error) => void;
    }
  >();
  private buffer = "";
  private repoPath: string;
  private accumulatedText = "";
  private terminals = new Map<
    string,
    { process: Deno.ChildProcess; stdout: string; stderr: string; exitCode: number | null }
  >();

  constructor(repoPath: string) {
    this.repoPath = repoPath;
    this.process = new Deno.Command("opencode", {
      args: ["acp"],
      stdin: "piped",
      stdout: "piped",
      stderr: "piped",
      cwd: repoPath,
    }).spawn();

    this.writer = this.process.stdin.getWriter();

    // Log stderr
    this.drainStderr();
  }

  private drainStderr(): void {
    const reader = this.process.stderr.getReader();
    const decoder = this.decoder;
    (async () => {
      try {
        while (true) {
          const { done, value } = await reader.read();
          if (done) break;
          const text = decoder.decode(value, { stream: true });
          await Deno.writeTextFile("/tmp/agent-opencode-stderr.log", text, {
            append: true,
          });
        }
      } catch {
        // Stream closed
      }
    })();
  }

  private send(msg: Record<string, unknown>): void {
    const line = JSON.stringify(msg) + "\n";
    this.writer.write(this.encoder.encode(line));
  }

  private sendRequest(
    method: string,
    params: Record<string, unknown>
  ): Promise<Record<string, unknown>> {
    const id = this.nextId++;
    return new Promise((resolve, reject) => {
      this.pendingRequests.set(id, { resolve, reject });
      this.send({ jsonrpc: "2.0", id, method, params });
    });
  }

  private sendResponse(
    id: number,
    result: Record<string, unknown>
  ): void {
    this.send({ jsonrpc: "2.0", id, result });
  }

  private sendErrorResponse(
    id: number,
    code: number,
    message: string
  ): void {
    this.send({ jsonrpc: "2.0", id, error: { code, message } });
  }

  private handleMessage(msg: JsonRpcMessage): void {
    // Response to one of our requests
    if ("id" in msg && ("result" in msg || "error" in msg)) {
      const resp = msg as JsonRpcResponse;
      const pending = this.pendingRequests.get(resp.id);
      if (pending) {
        this.pendingRequests.delete(resp.id);
        if (resp.error) {
          pending.reject(
            new Error(`${resp.error.message} (code ${resp.error.code})`)
          );
        } else {
          pending.resolve(resp.result || {});
        }
      }
      return;
    }

    // Notification from agent (no id, or id with method = request from agent)
    if ("method" in msg) {
      const method = (msg as JsonRpcNotification | JsonRpcRequest).method;
      const params = (msg as JsonRpcNotification | JsonRpcRequest).params || {};

      // Bidirectional requests from agent (have an id)
      if ("id" in msg && typeof (msg as JsonRpcRequest).id === "number") {
        this.handleAgentRequest(
          (msg as JsonRpcRequest).id,
          method,
          params
        );
        return;
      }

      // Notifications (session/update)
      this.handleNotification(method, params);
    }
  }

  /** Resolve a path: if relative, join with repoPath. */
  private resolvePath(p: string): string {
    if (p.startsWith("/")) return p;
    return `${this.repoPath}/${p}`;
  }

  private handleAgentRequest(
    id: number,
    method: string,
    params: Record<string, unknown>
  ): void {
    switch (method) {
      case "fs/read_text_file": {
        const path = this.resolvePath(params.path as string);
        try {
          const content = Deno.readTextFileSync(path);
          this.sendResponse(id, { content });
        } catch {
          this.sendErrorResponse(id, -32001, `File not found: ${path}`);
        }
        break;
      }

      case "fs/write_text_file": {
        const path = this.resolvePath(params.path as string);
        const content = params.content as string;
        try {
          // Ensure parent directory exists
          const dir = path.substring(0, path.lastIndexOf("/"));
          if (dir) {
            try { Deno.mkdirSync(dir, { recursive: true }); } catch { /* exists */ }
          }
          Deno.writeTextFileSync(path, content);
          emit("status", `Wrote file: ${path}`);
          this.sendResponse(id, {});
        } catch (e) {
          this.sendErrorResponse(
            id,
            -32002,
            `Write failed: ${e instanceof Error ? e.message : String(e)}`
          );
        }
        break;
      }

      case "fs/list_directory": {
        const path = this.resolvePath(params.path as string);
        try {
          const entries: { name: string; type: string }[] = [];
          for (const entry of Deno.readDirSync(path)) {
            entries.push({
              name: entry.name,
              type: entry.isDirectory ? "directory" : "file",
            });
          }
          this.sendResponse(id, { entries });
        } catch {
          this.sendErrorResponse(id, -32001, `Directory not found: ${path}`);
        }
        break;
      }

      case "session/request_permission": {
        // Auto-approve by selecting the first "allow" option
        const options = (params.options as { optionId: string; kind: string; name: string }[]) || [];
        const allowOption = options.find(
          (o) => o.kind === "allow_always" || o.kind === "allow_once"
        ) || options[0];
        const optionId = allowOption?.optionId || "allow";
        emit("status", `Auto-approved permission: ${allowOption?.name || method}`);
        this.sendResponse(id, { outcome: { type: "selected", optionId } });
        break;
      }

      case "terminal/create": {
        const termId = `term_${Date.now()}`;
        this.sendResponse(id, { terminalId: termId });
        break;
      }

      case "terminal/execute": {
        const command = params.command as string;
        const cwd = (params.cwd as string) || this.repoPath;
        (async () => {
          try {
            const result = await exec(["sh", "-c", command], { cwd });
            this.sendResponse(id, {
              exitCode: result.code,
              stdout: result.stdout,
              stderr: result.stderr,
            });
          } catch (e) {
            this.sendErrorResponse(
              id,
              -32002,
              `Exec failed: ${e instanceof Error ? e.message : String(e)}`
            );
          }
        })();
        break;
      }

      case "terminal/output": {
        // terminal/output sends input to a terminal; run the command
        const terminalId = params.terminalId as string;
        const input = params.data as string || params.input as string || "";
        const cwd = this.repoPath;
        (async () => {
          try {
            const result = await exec(["sh", "-c", input.trim()], { cwd });
            // Store result for wait_for_exit
            this.terminals.set(terminalId, {
              process: null as unknown as Deno.ChildProcess,
              stdout: result.stdout,
              stderr: result.stderr,
              exitCode: result.code,
            });
            this.sendResponse(id, {});
          } catch (e) {
            this.sendErrorResponse(
              id,
              -32002,
              `Terminal output failed: ${e instanceof Error ? e.message : String(e)}`
            );
          }
        })();
        break;
      }

      case "terminal/wait_for_exit": {
        const terminalId = params.terminalId as string;
        const terminal = this.terminals.get(terminalId);
        if (terminal) {
          this.sendResponse(id, {
            exitCode: terminal.exitCode ?? 0,
            stdout: terminal.stdout,
            stderr: terminal.stderr,
          });
          this.terminals.delete(terminalId);
        } else {
          this.sendResponse(id, { exitCode: 0, stdout: "", stderr: "" });
        }
        break;
      }

      case "terminal/kill": {
        const terminalId = params.terminalId as string;
        this.terminals.delete(terminalId);
        this.sendResponse(id, {});
        break;
      }

      case "terminal/release": {
        const terminalId = params.terminalId as string;
        this.terminals.delete(terminalId);
        this.sendResponse(id, {});
        break;
      }

      default:
        emit("status", `Unrecognized ACP method: ${method} (params: ${JSON.stringify(params).slice(0, 200)})`);
        this.sendErrorResponse(id, -32601, `Method not found: ${method}`);
    }
  }

  private handleNotification(
    method: string,
    params: Record<string, unknown>
  ): void {
    if (method !== "session/update") return;

    const update = params.update as Record<string, unknown> | undefined;
    if (!update) return;

    const updateType = (update.sessionUpdate as string) || (update.kind as string);
    const updateKind = (update.kind as string) || updateType || "unknown";
    const content = update.content as Record<string, unknown> | undefined;

    switch (updateType) {
      case "agent_message_chunk": {
        const textContent = content?.content as
          | { type: string; text?: string }[]
          | undefined;
        if (textContent) {
          for (const block of textContent) {
            if (block.type === "text" && block.text) {
              this.accumulatedText += block.text;
              emit("text", block.text, { acp_kind: updateType });
            }
          }
        } else if (typeof content?.text === "string") {
          this.accumulatedText += content.text as string;
          emit("text", content.text as string, { acp_kind: updateType });
        }
        break;
      }

      case "agent_thought_chunk": {
        const thought =
          (content?.thought as string) || (content?.text as string) || "";
        if (thought) {
          this.accumulatedText += thought;
          emit("thought", thought, { acp_kind: updateType });
        }
        break;
      }

      case "tool_call": {
        const title = (update.title as string) || updateKind || "tool";
        const rawInput = update.rawInput as Record<string, unknown> | undefined;
        emit("tool_call", title, {
          acp_kind: updateKind,
          tool_name: title,
          tool_call_id: update.toolCallId as string,
          arguments: rawInput ? JSON.stringify(rawInput).slice(0, 350) : "",
        });
        break;
      }

      case "tool_call_update": {
        const status = (update.status as string) || "";
        if (status !== "completed") {
          break;
        }

        const title = (update.title as string) || updateKind || "tool";

        let output = "";
        const updateContent = update.content as
          | { type?: string; content?: { type?: string; text?: string } }[]
          | undefined;

        if (updateContent && updateContent.length > 0) {
          for (const block of updateContent) {
            const text = block.content?.text;
            if (typeof text === "string" && text.trim() !== "") {
              output = text;
              break;
            }
          }
        }

        if (output.trim() === "") {
          break;
        }

        emit("tool_result", output.slice(0, 700), {
          acp_kind: updateKind,
          tool_name: title,
        });
        break;
      }

      case "plan": {
        const steps = content?.steps as string[] | undefined;
        if (steps) {
          emit("plan", steps.join("\n"), { acp_kind: updateType });
        }
        break;
      }

      case "usage_update":
        break;

      default:
        break;
    }
  }

  getAccumulatedText(): string {
    return this.accumulatedText;
  }

  clearAccumulatedText(): void {
    this.accumulatedText = "";
  }

  async initialize(): Promise<void> {
    const result = await this.sendRequest("initialize", {
      protocolVersion: 1,
      clientInfo: {
        name: "glossia-setup-agent",
        version: "1.0.0",
      },
      capabilities: {
        fileSystem: {
          readTextFile: true,
          writeTextFile: true,
        },
        terminal: {
          create: true,
        },
      },
      authenticationMethods: [],
    });

    emit("status", "Agent connected.");
  }

  async newSession(cwd: string): Promise<string> {
    const result = await this.sendRequest("session/new", {
      cwd,
      mcpServers: [],
    });

    const sessionId = result.sessionId as string;
    return sessionId;
  }

  async prompt(
    sessionId: string,
    text: string
  ): Promise<Record<string, unknown>> {
    const result = await this.sendRequest("session/prompt", {
      sessionId,
      prompt: [{ type: "text", text }],
    });

    return result;
  }

  /**
   * Read stdout line by line, dispatching each JSON-RPC message.
   * Runs until the stdout stream closes (agent exits).
   */
  async runEventLoop(): Promise<void> {
    const reader = this.process.stdout.getReader();

    try {
      while (true) {
        const { done, value } = await reader.read();
        if (done) break;

        this.buffer += this.decoder.decode(value, { stream: true });
        const lines = this.buffer.split("\n");
        this.buffer = lines.pop() || "";

        for (const line of lines) {
          if (!line.trim()) continue;
          try {
            const msg = JSON.parse(line) as JsonRpcMessage;
            this.handleMessage(msg);
          } catch {
            // Non-JSON line (e.g. logging), ignore
          }
        }
      }
    } catch {
      // Stream closed
    }
  }

  async close(): Promise<void> {
    try {
      this.writer.close();
    } catch {
      // Already closed
    }
    try {
      this.process.kill("SIGTERM");
    } catch {
      // Already exited
    }
  }
}

// ---------------------------------------------------------------------------
// File verification helpers
// ---------------------------------------------------------------------------

function glossiaMdExists(repoPath: string): boolean {
  try {
    Deno.statSync(`${repoPath}/GLOSSIA.md`);
    return true;
  } catch {
    return false;
  }
}

function extractGlossiaMdFromText(text: string): string | null {
  const fencePattern = /```[a-z]*\n([\s\S]*?)\n```/g;
  let best: string | null = null;

  let match: RegExpExecArray | null;
  while ((match = fencePattern.exec(text)) !== null) {
    const block = match[1].trim();
    if (block.includes("+++") && block.includes("[[content]]")) {
      if (!best || block.length > best.length) {
        best = block;
      }
    }
  }

  if (!best) {
    const plusPlusPattern = /(\+\+\+[\s\S]*?\+\+\+[\s\S]*)/;
    const m = plusPlusPattern.exec(text);
    if (m && m[1].includes("[[content]]")) {
      best = m[1].trim();
    }
  }

  return best;
}

// ---------------------------------------------------------------------------
// Main
// ---------------------------------------------------------------------------

async function main(): Promise<void> {
  const args = parseArgs();
  const config = await readConfig(args.configPath);

  await init({
    serverUrl: args.serverUrl,
    token: args.token,
    projectId: args.projectId,
  });

  try {
    // 1. Clone repository
    await cloneRepo(config);

    // 2. Install OpenCode
    await installOpenCode();

    // 3. Write OpenCode config
    await writeOpenCodeConfig(config);

    // 4. Build prompt
    const promptText = buildPrompt(config);
    emit("prompt", promptText, {
      docs_ref: "/docs/reference/glossia-md",
      prompt_version: "setup-v2",
    });

    // 5. Start OpenCode via ACP
    const client = new AcpClient(config.repo_path);

    // Start reading events in background
    const eventLoopPromise = client.runEventLoop();

    try {
      // 6. ACP handshake
      await client.initialize();

      // 7. Create session
      const sessionId = await client.newSession(config.repo_path);

      // 8. Send prompt and wait for completion
      const result = await client.prompt(sessionId, promptText);
      const stopReason = (result.stopReason as string) || "unknown";

      if (stopReason !== "end_turn" && stopReason !== "done") {
        fail(`Agent stopped with reason: ${stopReason}`);
        return;
      }

      // 9. Verify GLOSSIA.md was written; retry if not
      if (!glossiaMdExists(config.repo_path)) {
        emit("status", "GLOSSIA.md not found after first attempt, retrying...");
        client.clearAccumulatedText();

        const retryPrompt = [
          "CRITICAL: The GLOSSIA.md file was NOT written to disk. You must write it now.",
          "",
          `Write the file to the absolute path: ${config.repo_path}/GLOSSIA.md`,
          "The file must contain TOML frontmatter (between +++ markers) with [[content]] entries",
          "and free-text context below the frontmatter. This is the only required deliverable.",
          "",
          "Write the complete file content now. Do not explain, just write the file.",
        ].join("\n");

        const retryResult = await client.prompt(sessionId, retryPrompt);
        const retryStop = (retryResult.stopReason as string) || "unknown";

        if (retryStop !== "end_turn" && retryStop !== "done") {
          fail(`Agent retry stopped with reason: ${retryStop}`);
          return;
        }
      }

      // 10. Final fallback: extract from accumulated text and write directly
      if (!glossiaMdExists(config.repo_path)) {
        emit("status", "Attempting to extract GLOSSIA.md from agent output...");
        const allText = client.getAccumulatedText();
        const extracted = extractGlossiaMdFromText(allText);

        if (extracted) {
          const filePath = `${config.repo_path}/GLOSSIA.md`;
          Deno.writeTextFileSync(filePath, extracted);
          emit("status", "Wrote GLOSSIA.md from extracted agent output.");
        }
      }

      complete();
    } finally {
      await client.close();
      await eventLoopPromise.catch(() => {});
    }
  } catch (error: unknown) {
    const message = error instanceof Error ? error.message : String(error);
    console.error("Setup failed:", message);
    fail(message);
    Deno.exit(1);
  }
}

main();
