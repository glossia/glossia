#!/usr/bin/env bun
import { writeFile } from 'node:fs/promises';
import process from 'node:process';

type Args = {
  baseUrl: string;
  output: string;
};

async function main(): Promise<void> {
  const args = parseArgs(process.argv.slice(2));

  const normalizedBaseUrl = args.baseUrl.replace(/\/+$/, '');

  const content = `# yaml-language-server: $schema=https://raw.githubusercontent.com/aquaproj/aqua/main/json-schema/registry.json
packages:
  - type: http
    repo_owner: glossia
    repo_name: glossia
    description: Localize like you ship software
    version_source: github_tag
    version_filter: not (Version contains "-")
    url: ${normalizedBaseUrl}/{{.Version}}/glossia-{{.OS}}-{{.Arch}}.{{.Format}}
    format: tar.gz
    files:
      - name: glossia
        src: glossia
    replacements:
      amd64: x64
    overrides:
      - goos: windows
        format: zip
        files:
          - name: glossia
            src: glossia.exe
        supported_envs:
          - windows
          - amd64
    checksum:
      type: http
      url: ${normalizedBaseUrl}/{{.Version}}/SHA256SUMS
      algorithm: sha256
    supported_envs:
      - darwin
      - linux
      - amd64
      - arm64
`;

  await writeFile(args.output, content, 'utf8');
  process.stdout.write(`wrote Aqua registry config to ${args.output}\n`);
}

function parseArgs(argv: string[]): Args {
  let baseUrl = '';
  let output = '';

  for (let i = 0; i < argv.length; i += 1) {
    const token = argv[i] ?? '';

    if (token === '--base-url') {
      const value = argv[i + 1];
      if (!value || value.startsWith('-')) {
        throw new Error('--base-url requires a value');
      }
      baseUrl = value;
      i += 1;
      continue;
    }

    if (token === '--output') {
      const value = argv[i + 1];
      if (!value || value.startsWith('-')) {
        throw new Error('--output requires a value');
      }
      output = value;
      i += 1;
      continue;
    }

    throw new Error(`unknown argument: ${token}`);
  }

  if (!baseUrl.trim()) {
    throw new Error('--base-url is required');
  }

  if (!output.trim()) {
    throw new Error('--output is required');
  }

  return { baseUrl, output };
}

await main();
