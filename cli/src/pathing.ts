import path from 'node:path';

export function normalizeSlashes(input: string): string {
  return input.replaceAll('\\', '/');
}

export function relativePath(base: string, target: string): string {
  const rel = normalizeSlashes(path.relative(base, target));
  return rel.length === 0 ? '.' : rel;
}

export function isAncestor(dir: string, targetPath: string): boolean {
  const dirNorm = normalizeSlashes(path.resolve(dir));
  const targetNorm = normalizeSlashes(path.resolve(targetPath));

  return targetNorm === dirNorm || targetNorm.startsWith(`${dirNorm}/`);
}

export function globBase(pattern: string): string {
  const normalized = normalizeSlashes(pattern);
  const wildcardIndex = normalized.search(/[\*\?\[]/);

  if (wildcardIndex < 0) {
    const parent = normalizeSlashes(path.dirname(normalized));
    return parent || '.';
  }

  const prefix = normalized.slice(0, wildcardIndex);
  const parent = normalizeSlashes(path.dirname(prefix));
  return parent || '.';
}
