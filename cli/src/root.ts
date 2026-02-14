import path from 'node:path';
import { access } from 'node:fs/promises';

export async function findRoot(start: string): Promise<string> {
  let current = path.resolve(start);

  while (true) {
    try {
      await access(path.join(current, '.git'));
      return current;
    } catch {
      const parent = path.dirname(current);
      if (parent === current) {
        return path.resolve(start);
      }
      current = parent;
    }
  }
}

export async function resolveBaseDir(cwd: string, overridePath?: string): Promise<string> {
  if (!overridePath?.trim()) {
    return cwd;
  }

  const rawPath = overridePath.trim();
  const candidate = path.isAbsolute(rawPath) ? rawPath : path.join(cwd, rawPath);

  try {
    const { stat } = await import('node:fs/promises');
    const meta = await stat(candidate);
    if (meta.isDirectory()) {
      return candidate;
    }

    return path.dirname(candidate);
  } catch {
    return candidate;
  }
}
