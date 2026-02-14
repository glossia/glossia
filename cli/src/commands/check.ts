import path from 'node:path';
import { readFile } from 'node:fs/promises';
import { validate } from '../checks.js';
import { buildPlan, outputFormatLabel } from '../plan.js';
import type { Reporter } from '../reporter.js';

export type CheckOptions = {
  checkCmd: string;
  reporter: Reporter;
};

export async function checkCommand(root: string, options: CheckOptions): Promise<void> {
  const plan = await buildPlan(root);
  if (plan.sources.length === 0) {
    throw new Error('no sources found');
  }

  let total = 0;
  for (const source of plan.sources) {
    total += source.outputs.length;
  }

  let current = 0;

  for (const source of plan.sources) {
    const sourceText = await readFile(source.absPath, 'utf8');

    for (const output of source.outputs) {
      const outputAbs = path.join(root, output.outputPath);
      let outputText: string;

      try {
        outputText = await readFile(outputAbs, 'utf8');
      } catch {
        throw new Error(`missing output: ${output.outputPath}`);
      }

      current += 1;
      const label = outputFormatLabel(source.sourcePath, output);
      options.reporter.step('Validating', current, total, label);

      await validate(root, source.format, outputText, sourceText, {
        preserve: source.entry.preserve,
        checkCmd: options.checkCmd.trim() || source.entry.checkCmd || undefined,
        checkCmds: options.checkCmd.trim() ? undefined : source.entry.checkCmds,
        reporter: options.reporter,
        label,
        current,
        total,
      });
    }
  }
}
