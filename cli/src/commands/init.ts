import path from 'node:path';
import { access, writeFile } from 'node:fs/promises';
import type { Reporter } from '../reporter.js';

const STARTER_CONTENT = `+++
[llm]
provider = "openai"

[[llm.agent]]
role = "coordinator"
model = "gpt-4o-mini"

[[llm.agent]]
role = "translator"
model = "gpt-4o"

[[translate]]
source = "docs/*.md"
targets = ["es", "de"]
output = "docs/i18n/{lang}/{relpath}"
+++
Project context for translators goes here.
`;

export type InitOptions = {
  reporter: Reporter;
};

export async function initCommand(root: string, options: InitOptions): Promise<void> {
  const contentPath = path.join(root, 'CONTENT.md');

  try {
    await access(contentPath);
    throw new Error(`CONTENT.md already exists at ${contentPath}`);
  } catch (error) {
    if (error instanceof Error && error.message.startsWith('CONTENT.md already exists')) {
      throw error;
    }
  }

  await writeFile(contentPath, STARTER_CONTENT, 'utf8');
  options.reporter.log('Created', 'CONTENT.md');
}
