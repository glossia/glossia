import { describe, expect, test } from 'bun:test';
import { expandOutput } from './output.js';

describe('expandOutput', () => {
  test('expands placeholders', () => {
    expect(
      expandOutput('i18n/{lang}/{relpath}', {
        lang: 'es',
        relpath: 'docs/guide.md',
        basename: 'guide',
        ext: 'md',
      }),
    ).toBe('i18n/es/docs/guide.md');
  });

  test('normalizes slashes', () => {
    expect(
      expandOutput('out\\{lang}\\{basename}.{ext}', {
        lang: 'de',
        relpath: 'docs\\guide.md',
        basename: 'guide',
        ext: 'md',
      }),
    ).toBe('out/de/guide.md');
  });
});
