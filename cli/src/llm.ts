import process from 'node:process';
import type { AgentConfig } from './config.js';

export type ChatMessage = {
  role: 'system' | 'user' | 'assistant';
  content: string;
};

export type TokenUsage = {
  promptTokens: number;
  completionTokens: number;
  totalTokens: number;
};

const EMPTY_USAGE: TokenUsage = {
  promptTokens: 0,
  completionTokens: 0,
  totalTokens: 0,
};

type OpenAiUsage = {
  prompt_tokens?: number;
  completion_tokens?: number;
  total_tokens?: number;
};

type OpenAiResponse = {
  choices?: Array<{
    message?: {
      content?: string;
    };
  }>;
  usage?: OpenAiUsage;
  error?: {
    message?: string;
  };
};

type AnthropicResponse = {
  content?: Array<{
    type?: string;
    text?: string;
  }>;
  usage?: {
    input_tokens?: number;
    output_tokens?: number;
  };
  error?: {
    message?: string;
  };
};

export async function chat(
  cfg: AgentConfig,
  model: string,
  messages: ChatMessage[],
): Promise<{ text: string; usage: TokenUsage }> {
  const provider = cfg.provider.trim().toLowerCase();
  if (provider === 'anthropic') {
    return chatAnthropic(cfg, model, messages);
  }

  return chatOpenAi(cfg, model, messages);
}

async function chatOpenAi(
  cfg: AgentConfig,
  model: string,
  messages: ChatMessage[],
): Promise<{ text: string; usage: TokenUsage }> {
  if (!cfg.baseUrl.trim()) {
    throw new Error('llm base_url is required');
  }
  if (!model.trim()) {
    throw new Error('llm model is required');
  }

  const url = `${cfg.baseUrl.replace(/\/+$/, '')}${cfg.chatCompletionsPath}`;
  const body = {
    model,
    messages,
    temperature: cfg.temperature,
    max_tokens: cfg.maxTokens,
  };

  const headers = resolveHeaders(cfg);
  if (!hasHeader(headers, 'content-type')) {
    headers['Content-Type'] = 'application/json';
  }
  if (!hasHeader(headers, 'user-agent')) {
    headers['User-Agent'] = 'glossia';
  }

  const timeout = (cfg.timeoutSeconds > 0 ? cfg.timeoutSeconds : 300) * 1000;
  const response = await fetch(url, {
    method: 'POST',
    headers,
    body: JSON.stringify(body),
    signal: AbortSignal.timeout(timeout),
  });

  const rawBody = await response.text();
  const normalized = normalizeResponseBody(rawBody);
  const parsed = JSON.parse(normalized) as OpenAiResponse;

  if (response.status >= 400) {
    throw new Error(`llm error: ${parsed.error?.message ?? `status ${response.status}`}`);
  }

  const firstChoice = parsed.choices?.[0];
  const text = firstChoice?.message?.content ?? '';
  if (!text) {
    throw new Error('llm response missing choices');
  }

  return {
    text,
    usage: {
      promptTokens: parsed.usage?.prompt_tokens ?? 0,
      completionTokens: parsed.usage?.completion_tokens ?? 0,
      totalTokens: parsed.usage?.total_tokens ?? 0,
    },
  };
}

async function chatAnthropic(
  cfg: AgentConfig,
  model: string,
  messages: ChatMessage[],
): Promise<{ text: string; usage: TokenUsage }> {
  if (!cfg.baseUrl.trim()) {
    throw new Error('llm base_url is required');
  }
  if (!model.trim()) {
    throw new Error('llm model is required');
  }

  const url = `${cfg.baseUrl.replace(/\/+$/, '')}${cfg.chatCompletionsPath}`;

  const systemParts: string[] = [];
  const anthropicMessages: Array<{ role: 'user' | 'assistant'; content: string }> = [];

  for (const message of messages) {
    if (message.role === 'system') {
      if (message.content.trim()) {
        systemParts.push(message.content);
      }
      continue;
    }

    if (message.role === 'user' || message.role === 'assistant') {
      anthropicMessages.push({
        role: message.role,
        content: message.content,
      });
    }
  }

  if (anthropicMessages.length === 0) {
    throw new Error('llm request requires user messages');
  }

  const headers = resolveHeaders(cfg);
  if (!hasHeader(headers, 'content-type')) {
    headers['Content-Type'] = 'application/json';
  }
  if (!hasHeader(headers, 'user-agent')) {
    headers['User-Agent'] = 'glossia';
  }

  const timeout = (cfg.timeoutSeconds > 0 ? cfg.timeoutSeconds : 300) * 1000;
  const response = await fetch(url, {
    method: 'POST',
    headers,
    signal: AbortSignal.timeout(timeout),
    body: JSON.stringify({
      model,
      max_tokens: cfg.maxTokens && cfg.maxTokens > 0 ? cfg.maxTokens : 1024,
      messages: anthropicMessages,
      system: systemParts.length > 0 ? systemParts.join('\n\n') : undefined,
      temperature: cfg.temperature,
    }),
  });

  const parsed = (await response.json()) as AnthropicResponse;
  if (response.status >= 400) {
    throw new Error(`llm error: ${parsed.error?.message ?? `status ${response.status}`}`);
  }

  const text =
    parsed.content
      ?.filter((block) => block.type === 'text')
      .map((block) => block.text ?? '')
      .join('') ?? '';

  if (!text) {
    throw new Error('llm response missing text');
  }

  const input = parsed.usage?.input_tokens ?? 0;
  const output = parsed.usage?.output_tokens ?? 0;

  return {
    text,
    usage: {
      promptTokens: input,
      completionTokens: output,
      totalTokens: input + output,
    },
  };
}

function normalizeResponseBody(body: string): string {
  const trimmed = body.trim();

  if (!trimmed.startsWith('[')) {
    return trimmed;
  }

  const parsed = JSON.parse(trimmed) as unknown[];
  if (parsed.length !== 1) {
    throw new Error(`llm response: unexpected array with ${parsed.length} elements`);
  }

  const first = parsed[0] as { error?: { message?: string } };
  if (first?.error?.message) {
    throw new Error(`llm error: ${first.error.message}`);
  }

  return JSON.stringify(first);
}

function resolveHeaders(cfg: AgentConfig): Record<string, string> {
  const headers: Record<string, string> = {};

  for (const [key, value] of Object.entries(cfg.headers)) {
    headers[key] = expandEnv(value);
  }

  const provider = cfg.provider.trim().toLowerCase();
  if (provider === 'anthropic') {
    if (!hasHeader(headers, 'x-api-key')) {
      const key = resolveApiKey(cfg);
      if (key) {
        headers['x-api-key'] = key;
      }
    }
    if (!hasHeader(headers, 'anthropic-version')) {
      headers['anthropic-version'] = '2023-06-01';
    }
    return headers;
  }

  if (!hasHeader(headers, 'authorization')) {
    const key = resolveApiKey(cfg);
    if (key) {
      headers.Authorization = `Bearer ${key}`;
    }
  }

  return headers;
}

function resolveApiKey(cfg: AgentConfig): string {
  const fromInline = expandEnv(cfg.apiKey).trim();
  if (fromInline) {
    return fromInline;
  }

  if (!cfg.apiKeyEnv.trim()) {
    return '';
  }

  return process.env[cfg.apiKeyEnv] ?? '';
}

function hasHeader(headers: Record<string, string>, name: string): boolean {
  const normalized = name.toLowerCase();
  return Object.keys(headers).some((header) => header.toLowerCase() === normalized);
}

function expandEnv(input: string): string {
  const withTemplate = input.replace(/\{\{\s*env\.([A-Za-z_][A-Za-z0-9_]*)\s*\}\}/g, (_, key) => {
    return process.env[key] ?? '';
  });

  if (withTemplate.startsWith('env.')) {
    return process.env[withTemplate.slice(4)] ?? '';
  }

  return withTemplate.replace(/env:([A-Za-z_][A-Za-z0-9_]*)/g, (_, key) => process.env[key] ?? '');
}

export function addUsage(sum: TokenUsage, next: TokenUsage): TokenUsage {
  return {
    promptTokens: sum.promptTokens + next.promptTokens,
    completionTokens: sum.completionTokens + next.completionTokens,
    totalTokens: sum.totalTokens + next.totalTokens,
  };
}

export function emptyUsage(): TokenUsage {
  return { ...EMPTY_USAGE };
}
