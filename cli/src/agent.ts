import { validate } from './checks.js';
import type { AgentConfig } from './config.js';
import { FRONTMATTER_PRESERVE } from './config.js';
import type { Format } from './format.js';
import { addUsage, chat, emptyUsage, type TokenUsage } from './llm.js';
import type { Reporter } from './reporter.js';

export type TranslationRequest = {
  source: string;
  targetLang: string;
  format: Format;
  context: string;
  preserve: string[];
  frontmatter: string;
  checkCmd: string;
  checkCmds: Record<string, string>;
  reporter?: Reporter;
  progressLabel: string;
  progressCurrent: number;
  progressTotal: number;
  retries: number;
  coordinator: AgentConfig;
  translator: AgentConfig;
  root: string;
};

export type RevisitRequest = {
  source: string;
  format: Format;
  context: string;
  prompt: string;
  checkCmd: string;
  checkCmds: Record<string, string>;
  reporter?: Reporter;
  progressLabel: string;
  progressCurrent: number;
  progressTotal: number;
  retries: number;
  coordinator: AgentConfig;
  translator: AgentConfig;
  root: string;
};

export type TranslationResult = {
  text: string;
  usage: TokenUsage;
};

export async function translate(request: TranslationRequest): Promise<TranslationResult> {
  let content = request.source;
  let frontmatter = '';

  if (request.format === 'markdown' && request.frontmatter === FRONTMATTER_PRESERVE) {
    const split = splitMarkdownFrontmatter(request.source);
    if (split.ok) {
      frontmatter = split.frontmatter;
      content = split.body;
    }
  }

  const briefResult = await buildBrief(request);
  let usage = briefResult.usage;
  const brief = briefResult.text;

  const attempts = request.retries < 0 ? 0 : request.retries;
  let lastError: Error | undefined;

  for (let attempt = 0; attempt <= attempts; attempt += 1) {
    const result = await translateOnce(request, brief, content, lastError);
    usage = addUsage(usage, result.usage);

    let translated = stripStructuredCodeFence(request.format, result.text.trimEnd());
    if (frontmatter) {
      translated = translated.trim() ? `${frontmatter}\n${translated}` : `${frontmatter}\n`;
    }

    try {
      await validate(request.root, request.format, translated, request.source, {
        preserve: request.preserve,
        checkCmd: request.checkCmd || undefined,
        checkCmds: Object.keys(request.checkCmds).length > 0 ? request.checkCmds : undefined,
        reporter: request.reporter,
        label: request.progressLabel,
        current: request.progressCurrent,
        total: request.progressTotal,
      });

      return {
        text: translated,
        usage,
      };
    } catch (error) {
      lastError = normalizeError(error);
    }
  }

  throw lastError ?? new Error('translation failed');
}

export async function revisit(request: RevisitRequest): Promise<TranslationResult> {
  const attempts = request.retries < 0 ? 0 : request.retries;
  let usage = emptyUsage();
  let lastError: Error | undefined;

  for (let attempt = 0; attempt <= attempts; attempt += 1) {
    const result = await revisitOnce(request, lastError);
    usage = addUsage(usage, result.usage);

    const output = stripStructuredCodeFence(request.format, result.text.trimEnd());

    try {
      await validate(request.root, request.format, output, request.source, {
        preserve: [],
        checkCmd: request.checkCmd || undefined,
        checkCmds: Object.keys(request.checkCmds).length > 0 ? request.checkCmds : undefined,
        reporter: request.reporter,
        label: request.progressLabel,
        current: request.progressCurrent,
        total: request.progressTotal,
      });

      return {
        text: output,
        usage,
      };
    } catch (error) {
      lastError = normalizeError(error);
    }
  }

  throw lastError ?? new Error('revision failed');
}

async function buildBrief(
  request: TranslationRequest,
): Promise<{ text: string; usage: TokenUsage }> {
  if (!request.coordinator.model.trim()) {
    return {
      text: defaultBrief(request),
      usage: emptyUsage(),
    };
  }

  try {
    const response = await chat(request.coordinator, request.coordinator.model, [
      {
        role: 'system',
        content: 'You coordinate translations and produce concise briefs.',
      },
      {
        role: 'user',
        content: [
          'You are a localization coordinator.',
          'Create a short translation brief for the translator.',
          'The brief must be plain text and under 12 lines.',
          '',
          `Target language: ${request.targetLang}`,
          `Format: ${request.format}`,
          `Preserve: ${request.preserve.join(', ')}`,
          `Frontmatter mode: ${request.frontmatter}`,
          '',
          `Context:\n${request.context}`,
        ].join('\n'),
      },
    ]);

    return {
      text: response.text.trim(),
      usage: response.usage,
    };
  } catch {
    return {
      text: defaultBrief(request),
      usage: emptyUsage(),
    };
  }
}

async function translateOnce(
  request: TranslationRequest,
  brief: string,
  sourceContent: string,
  lastError?: Error,
): Promise<{ text: string; usage: TokenUsage }> {
  const model = request.translator.model.trim();
  if (!model) {
    throw new Error('translator model is required');
  }

  const userMessage = [
    `Translate to ${request.targetLang}.`,
    '',
    `Context:\n${request.context}`,
    '',
    `Source:\n${sourceContent}`,
    lastError
      ? `\nPrevious output failed validation: ${lastError.message}\nReturn a corrected full translation.`
      : '',
  ].join('\n');

  const response = await chat(request.translator, model, [
    {
      role: 'system',
      content: `You are a translation engine. Follow this brief:\n${brief}`,
    },
    {
      role: 'user',
      content: userMessage,
    },
  ]);

  return response;
}

async function revisitOnce(
  request: RevisitRequest,
  lastError?: Error,
): Promise<{ text: string; usage: TokenUsage }> {
  const model = request.translator.model.trim();
  if (!model) {
    throw new Error('translator model is required');
  }

  const promptInstruction =
    request.prompt || 'Review and improve this content for clarity and quality.';

  const userMessage = [
    request.context ? `Context:\n${request.context}` : '',
    `Source:\n${request.source}`,
    lastError
      ? `\nPrevious output failed validation: ${lastError.message}\nReturn a corrected version.`
      : '',
  ]
    .filter(Boolean)
    .join('\n\n');

  return chat(request.translator, model, [
    {
      role: 'system',
      content: [
        'You are a content revision engine.',
        promptInstruction,
        'Return only the revised content. Do not add commentary or explanations.',
      ].join('\n'),
    },
    {
      role: 'user',
      content: userMessage,
    },
  ]);
}

function defaultBrief(request: TranslationRequest): string {
  const lines = [
    'Translate the content faithfully and naturally.',
    'Preserve code blocks, inline code, URLs, and placeholders.',
    'Keep formatting, lists, and headings intact.',
    'Return only the translated content.',
  ];

  if (isStructuredFormat(request.format)) {
    lines.push(`Return valid ${request.format} only. Do not wrap in markdown fences.`);
  }

  if (request.frontmatter === FRONTMATTER_PRESERVE) {
    lines.push('Frontmatter is preserved separately; do not add new frontmatter.');
  }

  return lines.join('\n');
}

function isStructuredFormat(format: Format): boolean {
  return format === 'json' || format === 'yaml' || format === 'po';
}

function stripStructuredCodeFence(format: Format, text: string): string {
  if (!isStructuredFormat(format)) {
    return text;
  }

  const trimmed = text.trim();
  if (!trimmed.startsWith('```')) {
    return text;
  }

  const lines = trimmed.split('\n');
  if (lines.length < 2 || lines.at(-1)?.trim() !== '```') {
    return text;
  }

  return lines.slice(1, -1).join('\n');
}

function splitMarkdownFrontmatter(content: string): {
  frontmatter: string;
  body: string;
  ok: boolean;
} {
  const lines = content.split('\n');
  const marker = lines[0]?.trim();

  if (marker !== '---' && marker !== '+++') {
    return {
      frontmatter: '',
      body: content,
      ok: false,
    };
  }

  let end = -1;
  for (let i = 1; i < lines.length; i += 1) {
    if (lines[i]?.trim() === marker) {
      end = i;
      break;
    }
  }

  if (end < 0) {
    return {
      frontmatter: '',
      body: content,
      ok: false,
    };
  }

  return {
    frontmatter: lines.slice(0, end + 1).join('\n'),
    body: lines.slice(end + 1).join('\n'),
    ok: true,
  };
}

function normalizeError(error: unknown): Error {
  if (error instanceof Error) {
    return error;
  }

  return new Error(String(error));
}
