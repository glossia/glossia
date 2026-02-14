import path from 'node:path';
import { access, readFile, rm } from 'node:fs/promises';
import { buildPlan } from '../plan.js';
import { lockPath, type LockFile } from '../locks.js';
import { walkFiles } from '../glob.js';
import type { Reporter } from '../reporter.js';

export type CleanOptions = {
  dryRun: boolean;
  orphans: boolean;
  reporter: Reporter;
};

export async function cleanCommand(root: string, options: CleanOptions): Promise<void> {
  const plan = await buildPlan(root);
  if (plan.sources.length === 0) {
    throw new Error('no sources found');
  }

  const plannedSources = new Set(plan.sources.map((source) => source.sourcePath));

  let removed = 0;
  let missing = 0;
  let lockRemoved = 0;

  for (const source of plan.sources) {
    for (const output of source.outputs) {
      const absolute = path.join(root, output.outputPath);
      const result = await removeFile(absolute, options.dryRun);

      if (result === 'removed') {
        removed += 1;
        options.reporter.log('Removed', output.outputPath);
      } else if (result === 'missing') {
        missing += 1;
        options.reporter.log('Skipped', `${output.outputPath} (not found)`);
      }
    }

    const lockFilePath = lockPath(root, source.sourcePath);
    const lockResult = await removeFile(lockFilePath, options.dryRun);

    if (lockResult === 'removed') {
      lockRemoved += 1;
      options.reporter.log('Removed', lockFilePath);
    } else if (lockResult === 'missing') {
      missing += 1;
      options.reporter.log('Skipped', `${lockFilePath} (not found)`);
    }
  }

  if (options.orphans) {
    const lockDir = path.join(root, '.glossia', 'locks');
    let lockFiles: string[] = [];

    try {
      const allFiles = await walkFiles(lockDir);
      lockFiles = allFiles
        .filter((file) => file.endsWith('.lock'))
        .map((file) => path.join(lockDir, file));
    } catch {
      lockFiles = [];
    }

    for (const lockFilePath of lockFiles) {
      const lock = await readJson<LockFile>(lockFilePath);
      if (!lock) {
        continue;
      }

      const sourcePath = lock.source_path?.trim() || sourcePathFromLock(root, lockFilePath);
      if (plannedSources.has(sourcePath)) {
        continue;
      }

      for (const output of Object.values(lock.outputs ?? {})) {
        const absolute = path.join(root, output.path);
        const result = await removeFile(absolute, options.dryRun);

        if (result === 'removed') {
          removed += 1;
          options.reporter.log('Removed', output.path);
        } else if (result === 'missing') {
          missing += 1;
          options.reporter.log('Skipped', `${output.path} (not found)`);
        }
      }

      const result = await removeFile(lockFilePath, options.dryRun);
      if (result === 'removed') {
        lockRemoved += 1;
        options.reporter.log('Removed', lockFilePath);
      } else if (result === 'missing') {
        missing += 1;
        options.reporter.log('Skipped', `${lockFilePath} (not found)`);
      }
    }
  }

  options.reporter.log(
    'Cleaned',
    `${removed} files removed, ${missing} not found, ${lockRemoved} lockfiles removed`,
  );
}

async function removeFile(
  filePath: string,
  dryRun: boolean,
): Promise<'removed' | 'missing' | 'skipped'> {
  if (dryRun) {
    return 'skipped';
  }

  try {
    await access(filePath);
  } catch {
    return 'missing';
  }

  try {
    await rm(filePath, { force: false });
    return 'removed';
  } catch {
    return 'missing';
  }
}

async function readJson<T>(filePath: string): Promise<T | undefined> {
  try {
    const raw = await readFile(filePath, 'utf8');
    return JSON.parse(raw) as T;
  } catch {
    return undefined;
  }
}

function sourcePathFromLock(root: string, lockFilePath: string): string {
  const base = `${path.join(root, '.glossia', 'locks')}${path.sep}`;
  const normalizedLock = lockFilePath.replaceAll('\\', '/');
  const normalizedBase = base.replaceAll('\\', '/');

  const relative = normalizedLock.startsWith(normalizedBase)
    ? normalizedLock.slice(normalizedBase.length)
    : normalizedLock;

  return relative.replace(/\.lock$/, '').replaceAll('\\', '/');
}
