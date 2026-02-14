import path from 'node:path';
import { readdir } from 'node:fs/promises';
import { normalizeSlashes } from './pathing.js';

export async function walkFiles(root: string): Promise<string[]> {
  const files: string[] = [];

  async function visit(current: string): Promise<void> {
    const entries = await readdir(current, { withFileTypes: true });

    for (const entry of entries) {
      const absolute = path.join(current, entry.name);

      if (entry.isDirectory()) {
        if (entry.name === '.git') {
          continue;
        }
        await visit(absolute);
        continue;
      }

      if (!entry.isFile()) {
        continue;
      }

      const relative = normalizeSlashes(path.relative(root, absolute));
      files.push(relative);
    }
  }

  await visit(root);
  return files;
}

export function matchesGlob(candidatePath: string, pattern: string): boolean {
  const regex = globToRegExp(pattern);
  return regex.test(normalizeSlashes(candidatePath));
}

export function globToRegExp(pattern: string): RegExp {
  const normalized = normalizeSlashes(pattern);
  let output = '^';

  for (let i = 0; i < normalized.length; i += 1) {
    const char = normalized[i];
    if (!char) {
      continue;
    }

    if (char === '*') {
      const next = normalized[i + 1];
      if (next === '*') {
        const nextNext = normalized[i + 2];
        if (nextNext === '/') {
          output += '(?:.*/)?';
          i += 2;
          continue;
        }

        output += '.*';
        i += 1;
        continue;
      }

      output += '[^/]*';
      continue;
    }

    if (char === '?') {
      output += '[^/]';
      continue;
    }

    if (char === '[') {
      const close = normalized.indexOf(']', i + 1);
      if (close > i) {
        const cls = normalized.slice(i, close + 1);
        output += cls;
        i = close;
        continue;
      }
    }

    if ('\\.^$+(){}|'.includes(char)) {
      output += `\\${char}`;
      continue;
    }

    output += char;
  }

  output += '$';
  return new RegExp(output);
}

export function globFiles(pattern: string, files: string[]): string[] {
  const matcher = globToRegExp(pattern);
  return files.filter((file) => matcher.test(normalizeSlashes(file)));
}
