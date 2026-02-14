import path from 'node:path';

export type Format = 'markdown' | 'json' | 'yaml' | 'po' | 'text';

export function detectFormat(filePath: string): Format {
  const ext = path.extname(filePath).replace(/^\./, '').toLowerCase();

  switch (ext) {
    case 'md':
    case 'markdown':
      return 'markdown';
    case 'json':
      return 'json';
    case 'yaml':
    case 'yml':
      return 'yaml';
    case 'po':
    case 'pot':
      return 'po';
    default:
      return 'text';
  }
}

export function formatLabel(format: Format): string {
  switch (format) {
    case 'json':
      return 'JSON';
    case 'yaml':
      return 'YAML';
    case 'po':
      return 'PO';
    case 'markdown':
      return 'Markdown frontmatter';
    case 'text':
      return 'text';
  }
}
