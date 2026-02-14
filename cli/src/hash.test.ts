import { describe, expect, test } from 'bun:test';
import { hashString, hashStrings } from './hash.js';

describe('hash helpers', () => {
  test('returns stable sha256 hash', () => {
    expect(hashString('hello')).toBe(
      '2cf24dba5fb0a30e26e83b2ac5b9e29e1b161e5c1fa7425e73043362938b9824',
    );
  });

  test('hashStrings joins with blank line', () => {
    expect(hashStrings(['a', 'b'])).toBe(hashString('a\n\nb'));
  });
});
