const assert = require('node:assert/strict');
const { readFileSync, readdirSync } = require('node:fs');
const { join, resolve } = require('node:path');
const { test } = require('node:test');

const workflows = resolve(__dirname, '../workflows');
const standardRunners = new Set([
  'ubuntu-latest',
  'ubuntu-24.04',
  'ubuntu-24.04-arm',
  'macos-14',
  'macos-15',
  'macos-15-intel',
  'macos-26',
  'windows-latest',
]);

// actionlint validates YAML and matrix expressions. This additional policy
// check prevents a valid workflow from silently depending on self-hosted or
// paid larger runners. Matrix entries must use the same standard labels.
function assertStandardRunners(source, filename) {
  const selectors = [...source.matchAll(/^[ \t]+(runs-on|runs_on):[ \t]*(.*)$/gm)];
  assert.ok(selectors.length > 0, `${filename}: no runner selectors found`);

  for (const [, key, rawValue] of selectors) {
    const value = rawValue.trim().replace(/^(['"])(.*)\1$/, '$2');
    if (key === 'runs-on' && value === '${{ matrix.runs_on }}') {
      assert.ok(selectors.some(([, name]) => name === 'runs_on'), `${filename}: missing runner matrix`);
      continue;
    }
    assert.ok(standardRunners.has(value), `${filename}: unsupported runner ${value}`);
  }
}

for (const filename of readdirSync(workflows).filter(name => /\.ya?ml$/.test(name)).sort()) {
  test(`${filename} uses only standard GitHub-hosted runners`, () => {
    assertStandardRunners(readFileSync(join(workflows, filename), 'utf8'), filename);
  });
}

for (const runner of [
  'hetzner-docker',
  '[self-hosted, linux]',
  'ubuntu-24.04-16core',
  'macos-26-xlarge',
  "${{ github.event_name == 'pull_request' && 'ubuntu-latest' || 'hetzner-docker' }}",
]) {
  test(`rejects runner selection ${runner}`, () => {
    assert.throws(() => assertStandardRunners(`jobs:\n  test:\n    runs-on: ${runner}\n`, 'fixture.yml'));
  });
}

test('rejects a self-hosted runner hidden in a release matrix', () => {
  assert.throws(() => assertStandardRunners(`jobs:
  build:
    runs-on: \${{ matrix.runs_on }}
    strategy:
      matrix:
        include:
          - runs_on: ubuntu-24.04
          - runs_on: hetzner-docker
`, 'fixture.yml'));
});

test('workflow policy tests run for changes to any workflow', () => {
  const source = readFileSync(join(workflows, 'license-checks.yml'), 'utf8');
  assert.equal([...source.matchAll(/- '\.github\/workflows\/\*\*'/g)].length, 2);
  assert.ok(source.includes('node --test .github/tests/*.test.cjs'));
});
