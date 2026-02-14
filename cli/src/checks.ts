import path from 'node:path';
import { mkdir, rm, writeFile } from 'node:fs/promises';
import { randomUUID } from 'node:crypto';
import { spawn } from 'node:child_process';
import YAML from 'yaml';
import TOML from '@iarna/toml';
import { formatLabel, type Format } from './format.js';
import type { Reporter } from './reporter.js';

export type CheckOptions = {
  preserve: string[];
  checkCmd?: string;
  checkCmds?: Record<string, string>;
  reporter?: Reporter;
  label?: string;
  current?: number;
  total?: number;
};

const DEFAULT_PRESERVE = ['code_blocks', 'inline_code', 'urls', 'placeholders'];

export async function validate(
  root: string,
  format: Format,
  output: string,
  source: string,
  options: CheckOptions,
): Promise<void> {
  if (options.reporter && options.label) {
    options.reporter.step('Validating', options.current ?? 0, options.total ?? 0, options.label);
  }

  options.reporter?.log('Checking', `syntax-validator: parse ${formatLabel(format)}`);
  const syntaxError = validateSyntax(format, output, source);
  if (syntaxError) {
    throw new Error(`syntax-validator tool failed: ${syntaxError}`);
  }

  const preserveKinds = resolvePreserve(options.preserve);
  if (preserveKinds.length > 0) {
    options.reporter?.log('Checking', 'preserve-check: verify preserved tokens');
    const preserveError = validatePreserve(output, source, preserveKinds);
    if (preserveError) {
      throw new Error(`preserve-check tool failed: ${preserveError}`);
    }
  }

  const command = selectCheckCommand(format, options.checkCmd, options.checkCmds);
  if (command) {
    options.reporter?.log('Checking', 'custom-command: run check_cmd');
    await runExternal(root, command, output);
  }
}

export function validateSyntax(
  format: Format,
  output: string,
  source?: string,
): string | undefined {
  try {
    switch (format) {
      case 'json': {
        JSON.parse(output);
        return undefined;
      }
      case 'yaml': {
        YAML.parse(output);
        return undefined;
      }
      case 'po': {
        return validatePoThorough(output, source);
      }
      case 'markdown': {
        return validateMarkdown(output);
      }
      case 'text':
        return undefined;
    }
  } catch (error) {
    if (error instanceof Error) {
      return error.message;
    }

    return String(error);
  }
}

function validateMarkdown(content: string): string | undefined {
  const lines = content.split('\n');
  if (lines.length === 0) {
    return undefined;
  }

  const marker = lines[0]?.trim();
  if (marker !== '---' && marker !== '+++') {
    return undefined;
  }

  let end = -1;
  for (let i = 1; i < lines.length; i += 1) {
    if (lines[i]?.trim() === marker) {
      end = i;
      break;
    }
  }

  if (end < 0) {
    return `markdown frontmatter missing closing ${marker}`;
  }

  const frontmatter = lines.slice(1, end).join('\n');
  try {
    if (marker === '---') {
      YAML.parse(frontmatter);
    } else {
      TOML.parse(frontmatter);
    }
  } catch (error) {
    if (error instanceof Error) {
      return `markdown frontmatter invalid ${marker === '---' ? 'yaml' : 'toml'}: ${error.message}`;
    }

    return `markdown frontmatter invalid ${marker === '---' ? 'yaml' : 'toml'}`;
  }

  return undefined;
}

export function resolvePreserve(kinds: string[]): string[] {
  if (kinds.length === 0) {
    return [...DEFAULT_PRESERVE];
  }

  if (kinds.some((kind) => kind.trim().toLowerCase() === 'none')) {
    return [];
  }

  return kinds.map((kind) => kind.trim().toLowerCase()).filter(Boolean);
}

export function extractPreservables(source: string, preserveKinds: string[]): string[] {
  const set = new Set<string>();
  const output: string[] = [];

  function push(match: string): void {
    if (!set.has(match)) {
      set.add(match);
      output.push(match);
    }
  }

  let working = source;

  if (preserveKinds.includes('code_blocks')) {
    for (const match of source.matchAll(/```[\s\S]*?```/g)) {
      if (match[0]) {
        push(match[0]);
      }
    }
    working = working.replace(/```[\s\S]*?```/g, '');
  }

  if (preserveKinds.includes('inline_code')) {
    for (const match of working.matchAll(/`[^`\n]+`/g)) {
      if (match[0]) {
        push(match[0]);
      }
    }
  }

  if (preserveKinds.includes('urls')) {
    for (const match of working.matchAll(/https?:\/\/[^\s)"'<>]+/g)) {
      if (match[0]) {
        push(match[0]);
      }
    }
  }

  if (preserveKinds.includes('placeholders')) {
    for (const match of working.matchAll(/\{[^\s{}]+\}/g)) {
      if (match[0]) {
        push(match[0]);
      }
    }
  }

  return output;
}

export function validatePreserve(
  output: string,
  source: string,
  preserveKinds: string[],
): string | undefined {
  const tokens = extractPreservables(source, preserveKinds);
  const missing: string[] = [];

  for (const token of tokens) {
    if (!output.includes(token)) {
      missing.push(token);
      if (missing.length >= 5) {
        break;
      }
    }
  }

  if (missing.length > 0) {
    return `preserved tokens missing from output: ${JSON.stringify(missing)}`;
  }

  return undefined;
}

function selectCheckCommand(
  format: Format,
  fallback?: string,
  commands?: Record<string, string>,
): string {
  const formatCmd = commands?.[format];
  if (formatCmd?.trim()) {
    return formatCmd.trim();
  }

  return fallback?.trim() ?? '';
}

export async function runExternal(
  root: string,
  commandTemplate: string,
  content: string,
): Promise<void> {
  if (!root.trim()) {
    throw new Error('external check requires root path');
  }

  const tmpDir = path.join(root, '.glossia', 'tmp');
  await mkdir(tmpDir, { recursive: true });

  const tmpFile = path.join(tmpDir, `check-${Date.now()}-${randomUUID().slice(0, 8)}.tmp`);
  await writeFile(tmpFile, content, 'utf8');

  const command = commandTemplate.replaceAll('{path}', tmpFile);

  try {
    await runShellCommand(command, root);
  } finally {
    await rm(tmpFile, { force: true });
  }
}

async function runShellCommand(command: string, cwd: string): Promise<void> {
  const shell = process.platform === 'win32' ? 'cmd.exe' : 'sh';
  const args = process.platform === 'win32' ? ['/d', '/s', '/c', command] : ['-c', command];

  await new Promise<void>((resolve, reject) => {
    const child = spawn(shell, args, {
      cwd,
      stdio: ['ignore', 'pipe', 'pipe'],
    });

    let stdout = '';
    let stderr = '';

    child.stdout.on('data', (chunk) => {
      stdout += chunk.toString();
    });
    child.stderr.on('data', (chunk) => {
      stderr += chunk.toString();
    });

    child.on('error', (error) => {
      reject(new Error(`external check failed: ${error.message}`));
    });

    child.on('close', (code) => {
      if (code === 0) {
        resolve();
        return;
      }

      const combined = [stderr, stdout].filter(Boolean).join('\n').trim();
      reject(new Error(`external check failed: exit ${code ?? -1}\n${combined}`));
    });
  });
}

type PoEntry = {
  msgid: string;
  msgstr: string;
  hasPlural: boolean;
  pluralMsgstrs: Record<number, string>;
};

function validatePo(content: string): string | undefined {
  const lines = content.split('\n');
  let state = '';
  let hasMsgid = false;
  let hasMsgstr = false;

  for (const rawLine of lines) {
    const line = rawLine.trim();

    if (!line || line.startsWith('#')) {
      continue;
    }

    if (line.startsWith('msgid ')) {
      if (hasMsgid && !hasMsgstr) {
        return 'po entry missing msgstr';
      }
      hasMsgid = true;
      hasMsgstr = false;
      state = 'msgid';
      if (!hasQuotedString(line)) {
        return 'po msgid missing quoted string';
      }
      continue;
    }

    if (line.startsWith('msgid_plural ')) {
      if (state !== 'msgid') {
        return 'po msgid_plural without msgid';
      }
      if (!hasQuotedString(line)) {
        return 'po msgid_plural missing quoted string';
      }
      continue;
    }

    if (line.startsWith('msgstr')) {
      if (!hasMsgid) {
        return 'po msgstr without msgid';
      }
      hasMsgstr = true;
      state = 'msgstr';
      if (!hasQuotedString(line)) {
        return 'po msgstr missing quoted string';
      }
      continue;
    }

    if (line.startsWith('"')) {
      if (!state) {
        return 'po stray quoted string';
      }
      continue;
    }

    return `po invalid line: ${line}`;
  }

  if (hasMsgid && !hasMsgstr) {
    return 'po entry missing msgstr';
  }

  return undefined;
}

export function validatePoThorough(content: string, source?: string): string | undefined {
  const baseError = validatePo(content);
  if (baseError) {
    return baseError;
  }

  const entries = parsePoEntries(content);
  const hasHeader = entries.some((entry) => entry.msgid === '' && entry.msgstr !== '');
  if (!hasHeader && entries.length > 0) {
    return 'po file missing header entry (msgid "" with Content-Type)';
  }

  const headerEntry = entries.find((entry) => entry.msgid === '');
  const pluralCount = headerEntry ? extractPluralFormsCount(headerEntry.msgstr) : undefined;

  if (pluralCount) {
    for (const entry of entries) {
      if (!entry.hasPlural || entry.msgid === '') {
        continue;
      }

      const maxPlural = Math.max(-1, ...Object.keys(entry.pluralMsgstrs).map(Number));
      if (maxPlural + 1 !== pluralCount) {
        return `po plural forms mismatch: header declares nplurals=${pluralCount} but entry for "${truncate(entry.msgid, 40)}" has ${maxPlural + 1} forms`;
      }
    }
  }

  if (source) {
    const sourceEntries = parsePoEntries(source);
    const formatRegex = /%[sdfiu%]|%\([^)]+\)[sdfiu]|\{[0-9]+\}|\{[a-zA-Z_][a-zA-Z0-9_]*\}/g;

    for (const srcEntry of sourceEntries) {
      if (!srcEntry.msgid) {
        continue;
      }

      const translated = entries.find((entry) => entry.msgid === srcEntry.msgid);
      if (!translated || !translated.msgstr) {
        continue;
      }

      const srcFormats = [...srcEntry.msgstr.matchAll(formatRegex)].map((match) => match[0]);
      for (const fmt of srcFormats) {
        if (!translated.msgstr.includes(fmt)) {
          return `po format string "${fmt}" in source msgstr for "${truncate(srcEntry.msgid, 40)}" missing from translation`;
        }
      }
    }
  }

  const untranslated = entries.filter(
    (entry) => !entry.msgid && !entry.msgstr && Object.keys(entry.pluralMsgstrs).length === 0,
  );
  if (untranslated.length > 0) {
    return `po has ${untranslated.length} untranslated entries`;
  }

  return undefined;
}

function parsePoEntries(content: string): PoEntry[] {
  const entries: PoEntry[] = [];

  let msgid = '';
  let msgstr = '';
  let hasPlural = false;
  let pluralMsgstrs: Record<number, string> = {};
  let state = '';
  let pluralIndex: number | undefined;
  let inEntry = false;

  const pushCurrent = (): void => {
    if (!inEntry) {
      return;
    }

    entries.push({
      msgid,
      msgstr,
      hasPlural,
      pluralMsgstrs: { ...pluralMsgstrs },
    });

    msgid = '';
    msgstr = '';
    hasPlural = false;
    pluralMsgstrs = {};
    state = '';
    pluralIndex = undefined;
    inEntry = false;
  };

  for (const rawLine of content.split('\n')) {
    const line = rawLine.trim();

    if (!line || line.startsWith('#')) {
      pushCurrent();
      continue;
    }

    if (line.startsWith('msgid ')) {
      pushCurrent();
      inEntry = true;
      state = 'msgid';
      msgid = extractQuoted(line);
      continue;
    }

    if (line.startsWith('msgid_plural ')) {
      hasPlural = true;
      state = 'msgid_plural';
      continue;
    }

    if (line.startsWith('msgstr[')) {
      const idx = Number.parseInt(line.slice(7), 10);
      pluralIndex = Number.isNaN(idx) ? 0 : idx;
      state = 'msgstr_plural';
      pluralMsgstrs[pluralIndex] = extractQuoted(line);
      continue;
    }

    if (line.startsWith('msgstr ')) {
      state = 'msgstr';
      msgstr = extractQuoted(line);
      continue;
    }

    if (line.startsWith('"')) {
      const continuation = extractQuotedRaw(line);
      if (state === 'msgid') {
        msgid += continuation;
      } else if (state === 'msgstr') {
        msgstr += continuation;
      } else if (state === 'msgstr_plural' && pluralIndex !== undefined) {
        pluralMsgstrs[pluralIndex] = `${pluralMsgstrs[pluralIndex] ?? ''}${continuation}`;
      }
    }
  }

  pushCurrent();
  return entries;
}

function hasQuotedString(line: string): boolean {
  let count = 0;
  let escaped = false;

  for (const char of line) {
    if (char === '\\' && !escaped) {
      escaped = true;
      continue;
    }

    if (char === '"' && !escaped) {
      count += 1;
    }

    escaped = false;
  }

  return count >= 2;
}

function extractQuoted(line: string): string {
  const firstQuote = line.indexOf('"');
  if (firstQuote < 0) {
    return '';
  }

  return extractQuotedRaw(line.slice(firstQuote));
}

function extractQuotedRaw(line: string): string {
  const trimmed = line.trim();
  if (trimmed.length < 2 || !trimmed.startsWith('"') || !trimmed.endsWith('"')) {
    return '';
  }

  return trimmed
    .slice(1, -1)
    .replaceAll('\\n', '\n')
    .replaceAll('\\t', '\t')
    .replaceAll('\\"', '"')
    .replaceAll('\\\\', '\\');
}

function extractPluralFormsCount(header: string): number | undefined {
  const lines = [...header.split('\\n'), ...header.split('\n')];

  for (const line of lines) {
    const normalized = line.trim().toLowerCase();
    if (!normalized.startsWith('plural-forms:')) {
      continue;
    }

    const index = normalized.indexOf('nplurals=');
    if (index < 0) {
      continue;
    }

    const digits = normalized.slice(index + 'nplurals='.length).match(/^\d+/)?.[0];
    if (digits) {
      return Number.parseInt(digits, 10);
    }
  }

  return undefined;
}

function truncate(input: string, max: number): string {
  if (input.length <= max) {
    return input;
  }

  return `${input.slice(0, max)}...`;
}
