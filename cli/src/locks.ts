import path from 'node:path';
import { mkdir, readFile, writeFile } from 'node:fs/promises';

export type OutputLock = {
  path: string;
  hash: string;
  context_hash?: string;
  checked_at: string;
};

export type LockFile = {
  source_path: string;
  source_hash: string;
  context_hash?: string;
  outputs: Record<string, OutputLock>;
  updated_at: string;
};

export function createLock(sourcePath: string): LockFile {
  return {
    source_path: sourcePath,
    source_hash: '',
    outputs: {},
    updated_at: '',
  };
}

export function lockPath(root: string, sourcePath: string): string {
  return path.join(root, '.glossia', 'locks', `${sourcePath}.lock`);
}

export async function readLock(root: string, sourcePath: string): Promise<LockFile | undefined> {
  const filePath = lockPath(root, sourcePath);

  try {
    const raw = await readFile(filePath, 'utf8');
    return JSON.parse(raw) as LockFile;
  } catch {
    return undefined;
  }
}

export async function writeLock(root: string, sourcePath: string, lock: LockFile): Promise<void> {
  lock.updated_at = new Date().toISOString();

  const filePath = lockPath(root, sourcePath);
  await mkdir(path.dirname(filePath), { recursive: true });
  await writeFile(filePath, `${JSON.stringify(lock, null, 2)}\n`, 'utf8');
}
