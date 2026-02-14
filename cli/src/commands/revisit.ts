import path from 'node:path';
import { mkdir, readFile, writeFile } from 'node:fs/promises';
import { revisit } from '../agent.js';
import { hashBytes, hashString, hashStrings } from '../hash.js';
import { createLock, readLock, writeLock, type LockFile } from '../locks.js';
import {
  buildPlan,
  contextPartsFor,
  outputFormatLabel,
  outputLangKey,
  type SourcePlan,
} from '../plan.js';
import type { Reporter } from '../reporter.js';
import { addUsage, emptyUsage, type TokenUsage } from '../llm.js';

export type RevisitOptions = {
  force: boolean;
  retries: number;
  dryRun: boolean;
  checkCmd: string;
  reporter: Reporter;
};

type RevisitWorkItem = {
  source: SourcePlan;
  sourceBytes: Buffer;
  sourceHash: string;
  lock: LockFile;
  contextHashes: Record<string, string>;
  revisitMap: Record<string, boolean>;
};

export async function revisitCommand(root: string, options: RevisitOptions): Promise<void> {
  const plan = await buildPlan(root);
  const sources = plan.sources.filter((source) => source.kind === 'revisit');
  if (sources.length === 0) {
    throw new Error('no revisit sources found');
  }

  const workItems: RevisitWorkItem[] = [];
  let total = 0;

  for (const source of sources) {
    const sourceBytes = await readFile(source.absPath);
    const sourceHash = hashBytes(sourceBytes);
    const lock = (await readLock(root, source.sourcePath)) ?? createLock(source.sourcePath);

    const contextHashes: Record<string, string> = {};
    const revisitMap: Record<string, boolean> = {};

    for (const output of source.outputs) {
      const langKey = outputLangKey(output);
      const contextHash = hashStrings(contextPartsFor(source, langKey));
      contextHashes[langKey] = contextHash;

      const outputLock = lock.outputs[langKey];
      const upToDate =
        Boolean(outputLock) &&
        lock.source_hash === sourceHash &&
        outputLock?.path === output.outputPath &&
        lockContextHash(lock, langKey) === contextHash;

      if (!options.force && upToDate) {
        continue;
      }

      revisitMap[langKey] = true;
      total += 1;
    }

    workItems.push({
      source,
      sourceBytes,
      sourceHash,
      lock,
      contextHashes,
      revisitMap,
    });
  }

  if (total === 0) {
    options.reporter.log('Info', 'no revisions needed');
    return;
  }

  const first = workItems[0];
  if (first) {
    const coordinator = first.source.llm.coordinator.model.trim();
    const translatorModel = first.source.llm.translator.model.trim();
    if (coordinator) {
      options.reporter.log('Info', `coordinator: ${coordinator}, model: ${translatorModel}`);
    } else {
      options.reporter.log('Info', `model: ${translatorModel}`);
    }
  }

  let usage: TokenUsage = emptyUsage();
  let current = 0;

  for (const item of workItems) {
    const sourceText = item.sourceBytes.toString('utf8');

    for (const output of item.source.outputs) {
      const langKey = outputLangKey(output);
      if (!item.revisitMap[langKey]) {
        continue;
      }

      const step = current + 1;
      const label = outputFormatLabel(item.source.sourcePath, output);
      options.reporter.step('Revisiting', step, total, label);

      if (options.dryRun) {
        options.reporter.log('Dry run', label);
        current = step;
        continue;
      }

      let retries = options.retries;
      if (retries < 0 && item.source.entry.retries !== undefined) {
        retries = item.source.entry.retries;
      }
      if (retries < 0) {
        retries = 2;
      }

      const checkCmds = options.checkCmd.trim()
        ? {}
        : {
            ...item.source.entry.checkCmds,
          };

      const result = await revisit({
        source: sourceText,
        format: item.source.format,
        context: contextPartsFor(item.source, langKey).join('\n\n'),
        prompt: item.source.entry.prompt,
        checkCmd: options.checkCmd.trim() || item.source.entry.checkCmd,
        checkCmds,
        reporter: options.reporter,
        progressLabel: label,
        progressCurrent: step,
        progressTotal: total,
        retries,
        coordinator: item.source.llm.coordinator,
        translator: item.source.llm.translator,
        root,
      });

      usage = addUsage(usage, result.usage);

      const outputAbs = path.join(root, output.outputPath);
      await mkdir(path.dirname(outputAbs), { recursive: true });
      await writeFile(outputAbs, result.text, 'utf8');

      item.lock.source_hash = item.sourceHash;
      item.lock.outputs[langKey] = {
        path: output.outputPath,
        hash: hashString(result.text),
        context_hash: item.contextHashes[langKey] ?? '',
        checked_at: new Date().toISOString(),
      };

      await writeLock(root, item.source.sourcePath, item.lock);
      current = step;
    }
  }

  if (usage.totalTokens > 0) {
    options.reporter.log(
      'Summary',
      `${usage.promptTokens} prompt + ${usage.completionTokens} completion = ${usage.totalTokens} total tokens`,
    );
  }
}

function lockContextHash(lock: LockFile, lang: string): string {
  const fromOutput = lock.outputs[lang]?.context_hash;
  if (fromOutput?.trim()) {
    return fromOutput;
  }

  return lock.context_hash ?? '';
}
