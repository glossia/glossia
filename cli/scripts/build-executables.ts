import path from 'node:path';
import process from 'node:process';
import { mkdir } from 'node:fs/promises';
import { spawn } from 'node:child_process';

type Target = {
  target: string;
  output: string;
};

const TARGETS: Target[] = [
  { target: 'bun-linux-x64', output: 'glossia-linux-x64' },
  { target: 'bun-linux-arm64', output: 'glossia-linux-arm64' },
  { target: 'bun-darwin-x64', output: 'glossia-darwin-x64' },
  { target: 'bun-darwin-arm64', output: 'glossia-darwin-arm64' },
  { target: 'bun-windows-x64', output: 'glossia-windows-x64.exe' },
];

const INPUT = './src/main.ts';
const DIST_DIR = './dist/bin';

async function main(): Promise<void> {
  const selected = parseTargetsArg(process.argv.slice(2));

  await mkdir(DIST_DIR, { recursive: true });

  for (const item of selected) {
    const outputPath = path.join(DIST_DIR, item.output);
    await run(
      'bun',
      ['build', INPUT, '--compile', '--target', item.target, '--outfile', outputPath],
      process.cwd(),
    );

    process.stdout.write(`built ${item.target} -> ${outputPath}\n`);
  }
}

function parseTargetsArg(argv: string[]): Target[] {
  const index = argv.indexOf('--targets');
  if (index < 0) {
    return TARGETS;
  }

  const raw = argv[index + 1];
  if (!raw) {
    throw new Error('--targets requires a comma-separated value');
  }

  const requested = raw
    .split(',')
    .map((item) => item.trim())
    .filter(Boolean);

  if (requested.length === 0) {
    throw new Error('--targets cannot be empty');
  }

  const selected = TARGETS.filter((item) => requested.includes(item.target));
  if (selected.length !== requested.length) {
    const supported = TARGETS.map((item) => item.target).join(', ');
    throw new Error(`unsupported target requested. supported targets: ${supported}`);
  }

  return selected;
}

async function run(command: string, args: string[], cwd: string): Promise<void> {
  await new Promise<void>((resolve, reject) => {
    const child = spawn(command, args, {
      cwd,
      stdio: 'inherit',
    });

    child.on('error', (error) => {
      reject(error);
    });

    child.on('close', (code) => {
      if (code === 0) {
        resolve();
        return;
      }

      reject(new Error(`${command} ${args.join(' ')} failed with exit ${code ?? -1}`));
    });
  });
}

await main();
