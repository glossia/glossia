import { describe, expect, test } from 'bun:test';
import { validate, validateSyntax } from './checks.js';

describe('checks', () => {
  test('validateSyntax accepts valid json', () => {
    expect(validateSyntax('json', '{"ok":true}')).toBeUndefined();
  });

  test('validateSyntax rejects invalid json', () => {
    expect(validateSyntax('json', 'not-json')).toBeTruthy();
  });

  test('validate preserves inline code', async () => {
    await expect(
      validate(process.cwd(), 'text', 'Hola `code` mundo', 'Hello `code` world', {
        preserve: ['inline_code'],
      }),
    ).resolves.toBeUndefined();
  });

  test('validate fails when preserve token missing', async () => {
    await expect(
      validate(process.cwd(), 'text', 'Hola mundo', 'Hello `code` world', {
        preserve: ['inline_code'],
      }),
    ).rejects.toThrow();
  });
});
