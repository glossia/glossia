import process from 'node:process';

type Verb =
  | 'Translating'
  | 'Revisiting'
  | 'Validating'
  | 'Checking'
  | 'Ok'
  | 'Stale'
  | 'Missing'
  | 'Removed'
  | 'Skipped'
  | 'Cleaned'
  | 'Created'
  | 'Updated'
  | 'Summary'
  | 'Info'
  | 'Dry run';

const COLORS = {
  reset: '\u001b[0m',
  bold: '\u001b[1m',
  dim: '\u001b[2m',
  green: '\u001b[32m',
  cyan: '\u001b[36m',
  yellow: '\u001b[33m',
  red: '\u001b[31m',
  white: '\u001b[37m',
} as const;

function colorForVerb(verb: Verb): string {
  switch (verb) {
    case 'Ok':
    case 'Removed':
    case 'Cleaned':
    case 'Created':
    case 'Updated':
      return COLORS.green;
    case 'Translating':
    case 'Revisiting':
    case 'Validating':
    case 'Checking':
      return COLORS.cyan;
    case 'Stale':
    case 'Skipped':
    case 'Dry run':
      return COLORS.yellow;
    case 'Missing':
      return COLORS.red;
    default:
      return COLORS.white;
  }
}

function formatVerb(verb: Verb, useColor: boolean): string {
  const padded = verb.padStart(12, ' ');
  if (!useColor) {
    return padded;
  }

  return `${COLORS.bold}${colorForVerb(verb)}${padded}${COLORS.reset}`;
}

export interface Reporter {
  log(verb: Verb, message: string): void;
  step(verb: Verb, current: number, total: number, message: string): void;
  blank(): void;
}

export class ConsoleReporter implements Reporter {
  readonly #useColor: boolean;

  constructor(noColor = false) {
    this.#useColor = !noColor && Boolean(process.stdout.isTTY);
  }

  log(verb: Verb, message: string): void {
    process.stdout.write(`${formatVerb(verb, this.#useColor)}  ${message}\n`);
  }

  step(verb: Verb, current: number, total: number, message: string): void {
    const stepLabel = `[${current}/${total}] ${message}`;
    this.log(verb, stepLabel);
  }

  blank(): void {
    process.stdout.write('\n');
  }
}
