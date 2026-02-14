import path from 'node:path';
import process from 'node:process';
import { readFile } from 'node:fs/promises';
import TOML from '@iarna/toml';

export type AgentConfig = {
  role: string;
  provider: string;
  baseUrl: string;
  chatCompletionsPath: string;
  apiKey: string;
  apiKeyEnv: string;
  model: string;
  temperature?: number;
  maxTokens?: number;
  headers: Record<string, string>;
  timeoutSeconds: number;
};

export type ContentEntry = {
  source: string;
  path: string;
  targets: string[];
  output: string;
  exclude: string[];
  preserve: string[];
  frontmatter: string;
  prompt: string;
  check_cmd: string;
  check_cmds: Record<string, string>;
  retries?: number;
};

export type PartialAgentConfig = {
  role?: string;
  provider?: string;
  base_url?: string;
  chat_completions_path?: string;
  api_key?: string;
  api_key_env?: string;
  model?: string;
  temperature?: number;
  max_tokens?: number;
  headers?: Record<string, string>;
  timeout_seconds?: number;
};

export type LLMConfig = {
  provider?: string;
  base_url?: string;
  chat_completions_path?: string;
  api_key?: string;
  api_key_env?: string;
  coordinator_model?: string;
  translator_model?: string;
  temperature?: number;
  max_tokens?: number;
  headers?: Record<string, string>;
  timeout_seconds?: number;
  agent: PartialAgentConfig[];
};

export type ContentConfig = {
  llm: LLMConfig;
  content: ContentEntry[];
};

export type ContentFile = {
  path: string;
  dir: string;
  depth: number;
  body: string;
  config: ContentConfig;
};

export type Entry = {
  source: string;
  path: string;
  targets: string[];
  output: string;
  exclude: string[];
  preserve: string[];
  frontmatter: string;
  prompt: string;
  checkCmd: string;
  checkCmds: Record<string, string>;
  retries?: number;
  originPath: string;
  originDir: string;
  originDepth: number;
  index: number;
};

type RawConfig = {
  llm?: Record<string, unknown>;
  content?: Array<Record<string, unknown>>;
  translate?: Array<Record<string, unknown>>;
};

export const FRONTMATTER_PRESERVE = 'preserve';
export const FRONTMATTER_TRANSLATE = 'translate';

export type SplitResult = {
  frontmatter: string;
  body: string;
  hasFrontmatter: boolean;
};

export function splitTomlFrontmatter(contents: string): SplitResult {
  const lines = contents.split('\n');
  if (lines.length === 0 || lines[0]?.trim() !== '+++') {
    return {
      frontmatter: '',
      body: contents,
      hasFrontmatter: false,
    };
  }

  let end = -1;
  for (let i = 1; i < lines.length; i += 1) {
    if (lines[i]?.trim() === '+++') {
      end = i;
      break;
    }
  }

  if (end < 0) {
    throw new Error('frontmatter start found but no closing +++');
  }

  return {
    frontmatter: lines.slice(1, end).join('\n'),
    body: lines.slice(end + 1).join('\n'),
    hasFrontmatter: true,
  };
}

export async function parseContentFile(filePath: string): Promise<ContentFile> {
  const contents = await readFile(filePath, 'utf8');
  const split = splitTomlFrontmatter(contents);

  const config: ContentConfig = {
    llm: { agent: [] },
    content: [],
  };

  if (split.hasFrontmatter) {
    const parsed = TOML.parse(split.frontmatter) as RawConfig;

    config.llm = parseLlm(parsed.llm);

    const contentEntries = [...(parsed.content ?? []), ...(parsed.translate ?? [])];
    config.content = contentEntries.map(parseContentEntry);
  }

  for (const entry of config.content) {
    if (!entry.source) {
      entry.source = entry.path;
    }
    if (entry.targets.length > 0 && !entry.frontmatter) {
      entry.frontmatter = FRONTMATTER_PRESERVE;
    }
  }

  const absolutePath = path.resolve(filePath);

  return {
    path: absolutePath,
    dir: path.dirname(absolutePath),
    depth: 0,
    body: split.body,
    config,
  };
}

export function sourcePath(entry: ContentEntry): string {
  const source = entry.source.trim();
  if (source) {
    return source;
  }

  return entry.path.trim();
}

export function validateContentEntry(entry: ContentEntry): void {
  const source = sourcePath(entry);
  if (!source) {
    throw new Error('content entry requires source/path');
  }

  if (entry.targets.length > 0 && !entry.output.trim()) {
    throw new Error(`content entry "${source}" has targets but no output`);
  }

  if (
    entry.frontmatter &&
    entry.frontmatter !== FRONTMATTER_PRESERVE &&
    entry.frontmatter !== FRONTMATTER_TRANSLATE
  ) {
    throw new Error(
      `content entry "${source}" has invalid frontmatter mode "${entry.frontmatter}"`,
    );
  }
}

export function mergeLlm(base: LLMConfig, over: LLMConfig): LLMConfig {
  const out: LLMConfig = {
    ...base,
    agent: mergeAgents(base.agent ?? [], over.agent ?? []),
  };

  if (over.provider?.trim()) {
    out.provider = over.provider;
  }
  if (over.base_url?.trim()) {
    out.base_url = over.base_url;
  }
  if (over.chat_completions_path?.trim()) {
    out.chat_completions_path = over.chat_completions_path;
  }
  if (over.api_key?.trim()) {
    out.api_key = over.api_key;
  }
  if (over.api_key_env?.trim()) {
    out.api_key_env = over.api_key_env;
  }
  if (over.coordinator_model?.trim()) {
    out.coordinator_model = over.coordinator_model;
  }
  if (over.translator_model?.trim()) {
    out.translator_model = over.translator_model;
  }
  if (over.temperature !== undefined) {
    out.temperature = over.temperature;
  }
  if (over.max_tokens !== undefined) {
    out.max_tokens = over.max_tokens;
  }
  if ((over.timeout_seconds ?? 0) > 0) {
    out.timeout_seconds = over.timeout_seconds;
  }

  if (over.headers && Object.keys(over.headers).length > 0) {
    out.headers = {
      ...(base.headers ?? {}),
      ...over.headers,
    };
  }

  return out;
}

export function resolveAgents(llm: LLMConfig): {
  coordinator: AgentConfig;
  translator: AgentConfig;
} {
  const roleMap = new Map<string, PartialAgentConfig>();

  for (const agent of llm.agent ?? []) {
    const role = (agent.role ?? '').trim().toLowerCase();
    if (!role) {
      throw new Error('llm.agent requires role');
    }
    if (role !== 'coordinator' && role !== 'translator') {
      throw new Error(`unknown llm.agent role "${role}"`);
    }
    roleMap.set(role, agent);
  }

  const base = createEmptyAgent();
  base.provider = llm.provider ?? '';
  base.baseUrl = llm.base_url ?? '';
  base.chatCompletionsPath = llm.chat_completions_path ?? '';
  base.apiKey = llm.api_key ?? '';
  base.apiKeyEnv = llm.api_key_env ?? '';
  base.temperature = llm.temperature;
  base.maxTokens = llm.max_tokens;
  base.headers = { ...(llm.headers ?? {}) };
  base.timeoutSeconds = llm.timeout_seconds ?? 0;

  const coordinator = mergeAgent(base, roleMap.get('coordinator'));
  if (!coordinator.model.trim()) {
    coordinator.model = llm.coordinator_model ?? '';
  }
  applyAgentDefaults(coordinator);

  const translator = mergeAgent(base, roleMap.get('translator'));
  if (!translator.model.trim()) {
    translator.model = llm.translator_model ?? '';
  }

  if (!translator.provider.trim()) {
    translator.provider = coordinator.provider;
  }
  if (!translator.baseUrl.trim()) {
    translator.baseUrl = coordinator.baseUrl;
  }
  if (!translator.chatCompletionsPath.trim()) {
    translator.chatCompletionsPath = coordinator.chatCompletionsPath;
  }
  if (!translator.apiKey.trim()) {
    translator.apiKey = coordinator.apiKey;
  }
  if (!translator.apiKeyEnv.trim()) {
    translator.apiKeyEnv = coordinator.apiKeyEnv;
  }
  if (translator.temperature === undefined) {
    translator.temperature = coordinator.temperature;
  }
  if (translator.maxTokens === undefined) {
    translator.maxTokens = coordinator.maxTokens;
  }
  if (!translator.timeoutSeconds) {
    translator.timeoutSeconds = coordinator.timeoutSeconds;
  }
  translator.headers = {
    ...coordinator.headers,
    ...translator.headers,
  };
  applyAgentDefaults(translator);

  return { coordinator, translator };
}

function mergeAgents(base: PartialAgentConfig[], over: PartialAgentConfig[]): PartialAgentConfig[] {
  if (over.length === 0) {
    return [...base];
  }

  const out = [...base];

  for (const agent of over) {
    const role = (agent.role ?? '').trim().toLowerCase();
    if (!role) {
      out.push(agent);
      continue;
    }

    const idx = out.findIndex((item) => (item.role ?? '').trim().toLowerCase() === role);
    if (idx >= 0) {
      out[idx] = agent;
    } else {
      out.push(agent);
    }
  }

  return out;
}

function createEmptyAgent(): AgentConfig {
  return {
    role: '',
    provider: '',
    baseUrl: '',
    chatCompletionsPath: '',
    apiKey: '',
    apiKeyEnv: '',
    model: '',
    headers: {},
    timeoutSeconds: 0,
  };
}

function mergeAgent(base: AgentConfig, over?: PartialAgentConfig): AgentConfig {
  const out: AgentConfig = {
    ...base,
    headers: { ...base.headers },
  };

  if (!over) {
    return out;
  }

  if (over.provider?.trim()) {
    out.provider = over.provider;
  }
  if (over.base_url?.trim()) {
    out.baseUrl = over.base_url;
  }
  if (over.chat_completions_path?.trim()) {
    out.chatCompletionsPath = over.chat_completions_path;
  }
  if (over.api_key?.trim()) {
    out.apiKey = over.api_key;
  }
  if (over.api_key_env?.trim()) {
    out.apiKeyEnv = over.api_key_env;
  }
  if (over.model?.trim()) {
    out.model = over.model;
  }
  if (over.temperature !== undefined) {
    out.temperature = over.temperature;
  }
  if (over.max_tokens !== undefined) {
    out.maxTokens = over.max_tokens;
  }
  if ((over.timeout_seconds ?? 0) > 0) {
    out.timeoutSeconds = over.timeout_seconds ?? 0;
  }
  if (over.headers && Object.keys(over.headers).length > 0) {
    out.headers = {
      ...out.headers,
      ...over.headers,
    };
  }

  return out;
}

function inferProviderFromModel(model: string): string {
  const normalized = model.trim().toLowerCase();
  if (normalized.startsWith('gemini')) {
    return 'gemini';
  }
  if (normalized.startsWith('claude')) {
    return 'anthropic';
  }
  if (
    normalized.startsWith('gpt') ||
    normalized.startsWith('o1') ||
    normalized.startsWith('o3') ||
    normalized.startsWith('o4')
  ) {
    return 'openai';
  }

  return 'openai';
}

function applyAgentDefaults(cfg: AgentConfig): void {
  const provider = cfg.provider.trim() || inferProviderFromModel(cfg.model);
  cfg.provider = provider;

  switch (provider) {
    case 'openai': {
      if (!cfg.chatCompletionsPath.trim()) {
        cfg.chatCompletionsPath = '/chat/completions';
      }
      if (!cfg.baseUrl.trim()) {
        cfg.baseUrl = 'https://api.openai.com/v1';
      }
      if (!cfg.apiKeyEnv.trim()) {
        cfg.apiKeyEnv = 'OPENAI_API_KEY';
      }
      break;
    }
    case 'gemini': {
      if (!cfg.chatCompletionsPath.trim()) {
        cfg.chatCompletionsPath = '/chat/completions';
      }
      if (!cfg.baseUrl.trim()) {
        cfg.baseUrl = 'https://generativelanguage.googleapis.com/v1beta/openai';
      }
      if (!cfg.apiKeyEnv.trim()) {
        cfg.apiKeyEnv = 'GEMINI_API_KEY';
      }
      cfg.provider = 'openai';
      break;
    }
    case 'vertex': {
      if (!cfg.chatCompletionsPath.trim()) {
        cfg.chatCompletionsPath = '/chat/completions';
      }
      break;
    }
    case 'anthropic': {
      if (!cfg.chatCompletionsPath.trim()) {
        cfg.chatCompletionsPath = '/v1/messages';
      }
      if (!cfg.baseUrl.trim()) {
        cfg.baseUrl = 'https://api.anthropic.com';
      }
      if (!cfg.apiKeyEnv.trim()) {
        cfg.apiKeyEnv = 'ANTHROPIC_API_KEY';
      }
      break;
    }
    default:
      break;
  }
}

function parseLlm(input: RawConfig['llm']): LLMConfig {
  if (!input || typeof input !== 'object') {
    return { agent: [] };
  }

  const obj = input;
  const agents = asArray(obj.agent).map((item) => parsePartialAgent(item));

  return {
    provider: asString(obj.provider),
    base_url: asString(obj.base_url),
    chat_completions_path: asString(obj.chat_completions_path),
    api_key: asString(obj.api_key),
    api_key_env: asString(obj.api_key_env),
    coordinator_model: asString(obj.coordinator_model),
    translator_model: asString(obj.translator_model),
    temperature: asNumber(obj.temperature),
    max_tokens: asNumber(obj.max_tokens),
    headers: asRecord(obj.headers),
    timeout_seconds: asNumber(obj.timeout_seconds),
    agent: agents,
  };
}

function parsePartialAgent(input: unknown): PartialAgentConfig {
  if (!input || typeof input !== 'object') {
    return {};
  }

  const obj = input as Record<string, unknown>;

  return {
    role: asString(obj.role),
    provider: asString(obj.provider),
    base_url: asString(obj.base_url),
    chat_completions_path: asString(obj.chat_completions_path),
    api_key: asString(obj.api_key),
    api_key_env: asString(obj.api_key_env),
    model: asString(obj.model),
    temperature: asNumber(obj.temperature),
    max_tokens: asNumber(obj.max_tokens),
    headers: asRecord(obj.headers),
    timeout_seconds: asNumber(obj.timeout_seconds),
  };
}

function parseContentEntry(input: Record<string, unknown>): ContentEntry {
  return {
    source: asString(input.source),
    path: asString(input.path),
    targets: asStringArray(input.targets),
    output: asString(input.output),
    exclude: asStringArray(input.exclude),
    preserve: asStringArray(input.preserve),
    frontmatter: asString(input.frontmatter),
    prompt: asString(input.prompt),
    check_cmd: asString(input.check_cmd),
    check_cmds: asRecord(input.check_cmds),
    retries: asNumber(input.retries),
  };
}

function asString(value: unknown): string {
  return typeof value === 'string' ? value : '';
}

function asNumber(value: unknown): number | undefined {
  if (typeof value === 'number' && Number.isFinite(value)) {
    return value;
  }

  return undefined;
}

function asStringArray(value: unknown): string[] {
  if (!Array.isArray(value)) {
    return [];
  }

  return value.filter((item): item is string => typeof item === 'string');
}

function asArray(value: unknown): unknown[] {
  if (!Array.isArray(value)) {
    return [];
  }

  return value;
}

function asRecord(value: unknown): Record<string, string> {
  if (!value || typeof value !== 'object' || Array.isArray(value)) {
    return {};
  }

  const output: Record<string, string> = {};
  for (const [key, raw] of Object.entries(value)) {
    if (typeof raw === 'string') {
      output[key] = raw;
    }
  }

  return output;
}

export function collectEntries(contentFiles: ContentFile[]): Entry[] {
  const entries: Entry[] = [];

  for (const file of contentFiles) {
    file.config.content.forEach((raw, index) => {
      try {
        validateContentEntry(raw);
      } catch (error) {
        const message = error instanceof Error ? error.message : String(error);
        process.stderr.write(`warning: skipping invalid content entry: ${message}\n`);
        return;
      }

      entries.push({
        source: raw.source || raw.path,
        path: raw.path || raw.source,
        targets: [...raw.targets],
        output: raw.output,
        exclude: [...raw.exclude],
        preserve: [...raw.preserve],
        frontmatter:
          raw.frontmatter || (raw.targets.length > 0 ? FRONTMATTER_PRESERVE : raw.frontmatter),
        prompt: raw.prompt,
        checkCmd: raw.check_cmd,
        checkCmds: { ...raw.check_cmds },
        retries: raw.retries,
        originPath: file.path,
        originDir: file.dir,
        originDepth: file.depth,
        index,
      });
    });
  }

  return entries;
}
