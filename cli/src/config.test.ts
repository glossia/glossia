import { describe, expect, test } from 'bun:test';
import { splitTomlFrontmatter, sourcePath, validateContentEntry } from './config.js';

describe('config parsing helpers', () => {
  test('splitTomlFrontmatter without frontmatter', () => {
    const result = splitTomlFrontmatter('hello world');
    expect(result.hasFrontmatter).toBeFalse();
    expect(result.body).toBe('hello world');
  });

  test('splitTomlFrontmatter with frontmatter', () => {
    const result = splitTomlFrontmatter('+++\nkey = "value"\n+++\nbody');
    expect(result.hasFrontmatter).toBeTrue();
    expect(result.frontmatter).toBe('key = "value"');
    expect(result.body).toBe('body');
  });

  test('sourcePath prefers source', () => {
    expect(
      sourcePath({
        source: 'docs/*.md',
        path: '',
        targets: [],
        output: '',
        exclude: [],
        preserve: [],
        frontmatter: '',
        prompt: '',
        check_cmd: '',
        check_cmds: {},
      }),
    ).toBe('docs/*.md');
  });

  test('validateContentEntry requires output when targets exist', () => {
    expect(() =>
      validateContentEntry({
        source: 'docs/*.md',
        path: '',
        targets: ['es'],
        output: '',
        exclude: [],
        preserve: [],
        frontmatter: '',
        prompt: '',
        check_cmd: '',
        check_cmds: {},
      }),
    ).toThrow();
  });
});
