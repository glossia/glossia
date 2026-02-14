import path from 'node:path';
import { access, mkdir, readFile, writeFile } from 'node:fs/promises';
import { translate } from '../agent.js';
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

export type TranslateOptions = {
  force: boolean;
  yolo: boolean;
  retries: number;
  dryRun: boolean;
  checkCmd: string;
  reporter: Reporter;
};

type TranslateWorkItem = {
  source: SourcePlan;
  sourceBytes: Buffer;
  sourceHash: string;
  lock: LockFile;
  contextHashes: Record<string, string>;
  translateMap: Record<string, boolean>;
};

export async function translateCommand(root: string, options: TranslateOptions): Promise<void> {
  const plan = await buildPlan(root);
  const sources = plan.sources.filter((source) => source.kind === 'translate');
  if (sources.length === 0) {
    throw new Error('no translate sources found');
  }

  const workItems: TranslateWorkItem[] = [];
  let total = 0;

  for (const source of sources) {
    const sourceBytes = await readFile(source.absPath);
    const sourceHash = hashBytes(sourceBytes);
    const lock = (await readLock(root, source.sourcePath)) ?? createLock(source.sourcePath);

    const contextHashes: Record<string, string> = {};
    const translateMap: Record<string, boolean> = {};

    for (const output of source.outputs) {
      const langKey = outputLangKey(output);
      const contextHash = hashStrings(contextPartsFor(source, langKey));
      contextHashes[langKey] = contextHash;

      const outputAbs = path.join(root, output.outputPath);
      const missing = !(await exists(outputAbs));
      const outputLock = lock.outputs[langKey];
      const lockedContextHash = lockContextHash(lock, langKey);

      const upToDate =
        !missing &&
        Boolean(outputLock) &&
        lock.source_hash === sourceHash &&
        outputLock?.path === output.outputPath &&
        lockedContextHash === contextHash;

      if (!options.force && upToDate) {
        continue;
      }

      translateMap[langKey] = true;
      total += 1;
    }

    workItems.push({
      source,
      sourceBytes,
      sourceHash,
      lock,
      contextHashes,
      translateMap,
    });
  }

  if (total === 0) {
    options.reporter.log('Info', 'no translations needed');
    return;
  }

  const first = workItems[0];
  if (first) {
    const coordinator = first.source.llm.coordinator.model.trim();
    const translatorModel = first.source.llm.translator.model.trim();
    if (coordinator) {
      options.reporter.log('Info', `coordinator: ${coordinator}, translator: ${translatorModel}`);
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
      if (!item.translateMap[langKey]) {
        continue;
      }

      const step = current + 1;
      const label = outputFormatLabel(item.source.sourcePath, output);
      options.reporter.step('Translating', step, total, label);

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

      const result = await translate({
        source: sourceText,
        targetLang: langKey,
        format: item.source.format,
        context: contextPartsFor(item.source, langKey).join('\n\n'),
        preserve: [...item.source.entry.preserve],
        frontmatter: item.source.entry.frontmatter,
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

async function exists(filePath: string): Promise<boolean> {
  try {
    await access(filePath);
    return true;
  } catch {
    return false;
  }
}
