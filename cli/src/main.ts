#!/usr/bin/env bun
import process from 'node:process';
import { resolveBaseDir, findRoot } from './root.js';
import { ConsoleReporter } from './reporter.js';
import { initCommand } from './commands/init.js';
import { translateCommand } from './commands/translate.js';
import { revisitCommand } from './commands/revisit.js';
import { checkCommand } from './commands/check.js';
import { statusCommand } from './commands/status.js';
import { cleanCommand } from './commands/clean.js';

type Command = 'init' | 'translate' | 'revisit' | 'check' | 'status' | 'clean';

type ParsedGlobalFlags = {
  noColor: boolean;
  path?: string;
};

type ParsedArgs = {
  command: Command;
  commandArgs: string[];
  global: ParsedGlobalFlags;
};

async function main(): Promise<void> {
  const parsed = parseArgs(process.argv.slice(2));
  const cwd = process.cwd();
  const baseDir = await resolveBaseDir(cwd, parsed.global.path);
  const root = await findRoot(baseDir);
  const reporter = new ConsoleReporter(parsed.global.noColor || Boolean(process.env.NO_COLOR));

  try {
    switch (parsed.command) {
      case 'init': {
        await initCommand(root, { reporter });
        break;
      }
      case 'translate': {
        const options = parseTranslateOptions(parsed.commandArgs);
        await translateCommand(root, {
          ...options,
          reporter,
        });
        break;
      }
      case 'revisit': {
        const options = parseRevisitOptions(parsed.commandArgs);
        await revisitCommand(root, {
          ...options,
          reporter,
        });
        break;
      }
      case 'check': {
        const options = parseCheckOptions(parsed.commandArgs);
        await checkCommand(root, {
          ...options,
          reporter,
        });
        break;
      }
      case 'status': {
        ensureNoUnexpectedFlags(parsed.commandArgs);
        await statusCommand(root, { reporter });
        break;
      }
      case 'clean': {
        const options = parseCleanOptions(parsed.commandArgs);
        await cleanCommand(root, {
          ...options,
          reporter,
        });
        break;
      }
    }
  } catch (error) {
    reporter.blank();
    process.stderr.write(`${normalizeError(error).message}\n`);
    process.exitCode = 1;
  }
}

function parseArgs(argv: string[]): ParsedArgs {
  if (argv.length === 0 || argv.includes('--help') || argv.includes('-h')) {
    printHelp();
    process.exit(0);
  }

  const global: ParsedGlobalFlags = {
    noColor: false,
  };

  let command: Command | undefined;
  const commandArgs: string[] = [];

  for (let i = 0; i < argv.length; i += 1) {
    const token = argv[i] ?? '';

    if (token === '--no-color') {
      global.noColor = true;
      continue;
    }

    if (token === '--path') {
      const value = argv[i + 1];
      if (!value || value.startsWith('-')) {
        throw new Error('--path requires a value');
      }
      global.path = value;
      i += 1;
      continue;
    }

    if (!command && !token.startsWith('-')) {
      if (!isCommand(token)) {
        throw new Error(`unknown command: ${token}`);
      }
      command = token;
      continue;
    }

    if (command) {
      commandArgs.push(token);
      continue;
    }

    throw new Error(`unknown option: ${token}`);
  }

  if (!command) {
    throw new Error(
      'missing command (expected one of: init, translate, revisit, check, status, clean)',
    );
  }

  return {
    command,
    commandArgs,
    global,
  };
}

function parseTranslateOptions(argv: string[]): {
  force: boolean;
  yolo: boolean;
  retries: number;
  dryRun: boolean;
  checkCmd: string;
} {
  let force = false;
  let yolo = true;
  let noYolo = false;
  let retries = -1;
  let dryRun = false;
  let checkCmd = '';

  for (let i = 0; i < argv.length; i += 1) {
    const token = argv[i] ?? '';

    if (token === '--force') {
      force = true;
      continue;
    }
    if (token === '--yolo') {
      yolo = true;
      continue;
    }
    if (token === '--no-yolo') {
      noYolo = true;
      continue;
    }
    if (token === '--dry-run') {
      dryRun = true;
      continue;
    }
    if (token === '--retries') {
      const value = argv[i + 1];
      if (!value || value.startsWith('-')) {
        throw new Error('--retries requires a value');
      }
      retries = Number.parseInt(value, 10);
      if (Number.isNaN(retries)) {
        throw new Error('--retries must be a number');
      }
      i += 1;
      continue;
    }
    if (token === '--check-cmd') {
      const value = argv[i + 1];
      if (!value || value.startsWith('-')) {
        throw new Error('--check-cmd requires a value');
      }
      checkCmd = value;
      i += 1;
      continue;
    }

    throw new Error(`unknown translate flag: ${token}`);
  }

  return {
    force,
    yolo: noYolo ? false : yolo,
    retries,
    dryRun,
    checkCmd,
  };
}

function parseRevisitOptions(argv: string[]): {
  force: boolean;
  retries: number;
  dryRun: boolean;
  checkCmd: string;
} {
  let force = false;
  let retries = -1;
  let dryRun = false;
  let checkCmd = '';

  for (let i = 0; i < argv.length; i += 1) {
    const token = argv[i] ?? '';

    if (token === '--force') {
      force = true;
      continue;
    }
    if (token === '--dry-run') {
      dryRun = true;
      continue;
    }
    if (token === '--retries') {
      const value = argv[i + 1];
      if (!value || value.startsWith('-')) {
        throw new Error('--retries requires a value');
      }
      retries = Number.parseInt(value, 10);
      if (Number.isNaN(retries)) {
        throw new Error('--retries must be a number');
      }
      i += 1;
      continue;
    }
    if (token === '--check-cmd') {
      const value = argv[i + 1];
      if (!value || value.startsWith('-')) {
        throw new Error('--check-cmd requires a value');
      }
      checkCmd = value;
      i += 1;
      continue;
    }

    throw new Error(`unknown revisit flag: ${token}`);
  }

  return {
    force,
    retries,
    dryRun,
    checkCmd,
  };
}

function parseCheckOptions(argv: string[]): { checkCmd: string } {
  let checkCmd = '';

  for (let i = 0; i < argv.length; i += 1) {
    const token = argv[i] ?? '';

    if (token === '--check-cmd') {
      const value = argv[i + 1];
      if (!value || value.startsWith('-')) {
        throw new Error('--check-cmd requires a value');
      }
      checkCmd = value;
      i += 1;
      continue;
    }

    throw new Error(`unknown check flag: ${token}`);
  }

  return { checkCmd };
}

function parseCleanOptions(argv: string[]): { dryRun: boolean; orphans: boolean } {
  let dryRun = false;
  let orphans = false;

  for (const token of argv) {
    if (token === '--dry-run') {
      dryRun = true;
      continue;
    }

    if (token === '--orphans') {
      orphans = true;
      continue;
    }

    throw new Error(`unknown clean flag: ${token}`);
  }

  return { dryRun, orphans };
}

function ensureNoUnexpectedFlags(argv: string[]): void {
  if (argv.length > 0) {
    throw new Error(`unknown status flag: ${argv[0]}`);
  }
}

function isCommand(value: string): value is Command {
  return (
    value === 'init' ||
    value === 'translate' ||
    value === 'revisit' ||
    value === 'check' ||
    value === 'status' ||
    value === 'clean'
  );
}

function normalizeError(error: unknown): Error {
  if (error instanceof Error) {
    return error;
  }

  return new Error(String(error));
}

function printHelp(): void {
  process.stdout.write(`glossia - Localize like you ship software.

USAGE:
  glossia <command> [options]

COMMANDS:
  init       Initialize Glossia in this repo
  translate  Translate content to other languages
  revisit    Revisit content in the source language
  check      Validate outputs
  status     Report missing or stale outputs
  clean      Remove generated outputs and lockfiles

GLOBAL OPTIONS:
  --no-color        Disable color output
  --path <path>     Run as if in this directory

Run \'glossia <command> --help\' for command-specific flags.
`);
}

await main();
