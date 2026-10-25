import { test } from 'node:test';
import assert from 'node:assert/strict';
import { mkdtempSync, writeFileSync, rmSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { spawnSync } from 'node:child_process';
import { appleStrings, androidStrings, validateCatalog } from './validate_localizations.mjs';

const apple = '/* comment */ "A" = "Hello %1$@, %2$lld \\U2066path\\U2069";\n"B" = "Choose Files";';
const xml = '<?xml version="1.0" encoding="utf-8"?><resources><!-- keys --><string name="a" formatted="false">"Hello %1$s, %2$d &amp; \\u2066path\\u2069"</string></resources>';
test('valid translated values and reordered positional arguments', () => {
  validateCatalog(apple, apple.replace('Hello %1$@, %2$lld', '%2$lld مرحبًا %1$@').replace('Choose Files', 'Dateien wählen'), '.strings');
  validateCatalog(xml, xml.replace('Hello %1$s, %2$d', '%2$d שלום %1$s'), '.xml');
});
test('reject missing, added and duplicated keys', () => {
  for (const value of [apple.replace('"B" = "Choose Files";', ''), apple + '"C" = "extra";', apple + '"A" = "duplicate";']) assert.throws(() => validateCatalog(apple, value, '.strings'));
  assert.throws(() => androidStrings(xml.replace('</resources>', '<string name="a" formatted="false">"duplicate"</string></resources>')));
});
test('reject changed placeholder type, multiplicity, position and isolates', () => {
  for (const value of [apple.replace('%1$@', '%1$d'), apple.replace('%2$lld', ''), apple.replace('%1$@', '%3$@'), apple.replace('\\U2069', '')]) assert.throws(() => validateCatalog(apple, value, '.strings'));
  assert.throws(() => validateCatalog(xml, xml.replace('%1$s', '%1$d'), '.xml'));
});
test('fail closed on malformed syntax, entities, escapes, nesting and trailing content', () => {
  for (const value of ['"A" = "broken', '"A" "bad";', '/* unclosed', '"A" = "\\q";', '"A" = "ok"; garbage']) assert.throws(() => appleStrings(value));
  for (const value of [xml.replace('&amp;', '&unknown;'), xml.replace('</resources>', ''), xml.replace('Hello', '<b>Hi</b>'), xml + '<extra/>', xml.replace('formatted="false"', 'formatted="true"'), xml.replace('Hello', '\\q')]) assert.throws(() => androidStrings(value));
});
test('real env invocation validates candidate at its output path and returns nonzero on failure', () => {
  const directory = mkdtempSync(join(tmpdir(), 'glossia-native-validation-'));
  try {
    const source = join(directory, 'source.strings'), target = join(directory, 'candidate.strings');
    writeFileSync(source, apple); writeFileSync(target, apple);
    const run = () => spawnSync(process.execPath, ['tools/validate_localizations.mjs'], { cwd: new URL('..', import.meta.url), env: { ...process.env, GLOSSIA_SOURCE_PATH: source, GLOSSIA_TARGET_PATH: target, GLOSSIA_LOCALE: 'ar' }, encoding: 'utf8' });
    assert.equal(run().status, 0);
    writeFileSync(target, '"A" = "lost keys";'); assert.notEqual(run().status, 0);
    writeFileSync(target, Buffer.from([0xff, 0xfe])); assert.notEqual(run().status, 0);
  } finally { rmSync(directory, { recursive: true }); }
});
