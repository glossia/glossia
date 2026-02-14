import path from 'node:path';
import { access, readFile } from 'node:fs/promises';
import { hashBytes, hashStrings } from '../hash.js';
import { readLock, type LockFile } from '../locks.js';
import { buildPlan, contextPartsFor, outputFormatLabel, outputLangKey } from '../plan.js';
import type { Reporter } from '../reporter.js';

export type StatusOptions = {
  reporter: Reporter;
};

export async function statusCommand(root: string, options: StatusOptions): Promise<void> {
  const plan = await buildPlan(root);
  if (plan.sources.length === 0) {
    throw new Error('no sources found');
  }

  let missing = 0;
  let stale = 0;
  let ok = 0;

  for (const source of plan.sources) {
    const sourceBytes = await readFile(source.absPath);
    const sourceHash = hashBytes(sourceBytes);
    const lock = await readLock(root, source.sourcePath);

    for (const output of source.outputs) {
      const outputAbs = path.join(root, output.outputPath);
      const langKey = outputLangKey(output);
      const label = outputFormatLabel(source.sourcePath, output);

      if (!(await exists(outputAbs))) {
        missing += 1;
        options.reporter.log('Missing', label);
        continue;
      }

      const contextHash = hashStrings(contextPartsFor(source, langKey));
      if (!lock) {
        stale += 1;
        options.reporter.log('Stale', label);
        continue;
      }

      if (lock.source_hash !== sourceHash) {
        stale += 1;
        options.reporter.log('Stale', label);
        continue;
      }

      const outputLock = lock.outputs[langKey];
      if (!outputLock) {
        stale += 1;
        options.reporter.log('Stale', label);
        continue;
      }

      if (lockContextHash(lock, langKey) !== contextHash) {
        stale += 1;
        options.reporter.log('Stale', label);
        continue;
      }

      if (outputLock.path !== output.outputPath) {
        stale += 1;
        options.reporter.log('Stale', label);
        continue;
      }

      ok += 1;
      options.reporter.log('Ok', label);
    }
  }

  options.reporter.log('Summary', `${ok} ok, ${stale} stale, ${missing} missing`);

  if (stale > 0 || missing > 0) {
    throw new Error('outputs out of date');
  }
}

function lockContextHash(lock: LockFile, lang: string): string {
  const fromOutput = lock.outputs[lang]?.context_hash;
  if (fromOutput?.trim()) {
    return fromOutput;
  }

  return lock.context_hash ?? '';
}

async function exists(filePath: string): Promise<boolean> {
  try {
    await access(filePath);
    return true;
  } catch {
    return false;
  }
}
