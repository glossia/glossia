import { describe, expect, test } from 'bun:test';
import { detectFormat } from './format.js';

describe('detectFormat', () => {
  test('detects markdown', () => {
    expect(detectFormat('docs/guide.md')).toBe('markdown');
    expect(detectFormat('readme.markdown')).toBe('markdown');
  });

  test('detects json/yaml/po/text', () => {
    expect(detectFormat('data.json')).toBe('json');
    expect(detectFormat('config.yaml')).toBe('yaml');
    expect(detectFormat('messages.po')).toBe('po');
    expect(detectFormat('notes.txt')).toBe('text');
  });
});
