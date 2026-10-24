const assert = require('node:assert/strict');
const { spawnSync } = require('node:child_process');
const { appendFileSync, copyFileSync, existsSync, mkdirSync, mkdtempSync, readFileSync, rmSync, writeFileSync } = require('node:fs');
const { tmpdir } = require('node:os');
const { join, resolve } = require('node:path');
const { test } = require('node:test');

const root = resolve(__dirname, '../..');
const read = path => readFileSync(join(root, path), 'utf8');

function run(command, args, cwd, env = {}) {
  const result = spawnSync(command, args, {
    cwd, encoding: 'utf8', env: { ...process.env, ...env },
  });
  assert.equal(result.status, 0, `${command} ${args.join(' ')}\n${result.error || ''}\n${result.stderr}`);
  return result.stdout.trim();
}

function fixture(t) {
  const cwd = mkdtempSync(join(tmpdir(), 'glossia-app-release-'));
  t.after(() => rmSync(cwd, { recursive: true, force: true }));
  mkdirSync(join(cwd, 'app'));
  copyFileSync(join(root, 'app/cliff.toml'), join(cwd, 'app/cliff.toml'));
  const git = (...args) => run('git', args, cwd);
  git('init', '--initial-branch=main');
  git('config', 'user.name', 'Release Test');
  git('config', 'user.email', 'release@example.com');
  git('config', 'commit.gpgsign', 'false');
  git('config', 'tag.gpgsign', 'false');
  git('add', '.');
  git('commit', '-m', 'chore: initialize release config');

  function commit(message, path = 'app/lib/example.ex') {
    mkdirSync(resolve(cwd, path, '..'), { recursive: true });
    appendFileSync(join(cwd, path), `${message}\n`);
    git('add', '--', path);
    git('commit', '-m', message);
  }

  function prepare() {
    const output = join(cwd, '.git/outputs');
    writeFileSync(output, '');
    rmSync(join(cwd, 'app-release-notes.md'), { force: true });
    run('bash', [join(root, '.github/scripts/prepare-app-release.sh')], cwd, { GITHUB_OUTPUT: output });
    const values = Object.fromEntries(readFileSync(output, 'utf8').trim().split('\n').map(line => line.split('=')));
    const notes = existsSync(join(cwd, 'app-release-notes.md')) ? readFileSync(join(cwd, 'app-release-notes.md'), 'utf8') : '';
    return { ...values, notes };
  }

  return { git, commit, prepare, cwd };
}

test('the first app release ignores CLI, SDK, and historical unprefixed tags', t => {
  const f = fixture(t);
  for (const tag of ['cli-v90.0.0', 'sdk-v80.0.0', '0.2.0']) f.git('tag', tag);
  f.commit('feat: introduce the community edition (#123)');
  const release = f.prepare();
  assert.equal(release.should_release, 'true');
  assert.equal(release.tag_name, 'app-v0.1.0');
  assert.equal(release.version, '0.1.0');
  assert.equal(release.build_version, '0.1.0');
  assert.match(release.notes, /Features/);
  assert.match(release.notes, /introduce the community edition \(\[#123\]\(https:\/\/github.com\/glossia\/glossia\/pull\/123\)\)/);
  assert.doesNotMatch(release.notes, /\* feat:/);
});

for (const [message, version] of [
  ['fix: repair an app bug', '1.2.4'],
  ['feat(audit): add enterprise export', '1.3.0'],
  ['feat!: replace the API', '2.0.0'],
  ['chore!: remove an old configuration format', '2.0.0'],
  ['fix: replace the API\n\nBREAKING CHANGE: remove old routes', '2.0.0'],
]) {
  test(`${message.split('\n')[0]} calculates ${version}`, t => {
    const f = fixture(t);
    f.git('tag', 'app-v1.2.3');
    f.commit(message);
    const release = f.prepare();
    assert.equal(release.should_release, 'true');
    assert.equal(release.tag_name, `app-v${version}`);
    assert.equal(release.build_version, version);
    assert.match(release.notes, new RegExp(`compare/app-v1\\.2\\.3\\.\\.\\.app-v${version.replaceAll('.', '\\.')}`));
  });
}

test('enterprise-only changes advance the shared app version', t => {
  const f = fixture(t);
  f.git('tag', 'app-v1.2.3');
  f.commit('feat: add an audit sink', 'ee/lib/glossia_enterprise/audit.ex');
  assert.equal(f.prepare().tag_name, 'app-v1.3.0');
});

for (const path of ['cli/src/main.rs', 'sdk/web/src/index.ts', 'LICENSE.md', 'LICENSE-APACHE']) {
  test(`embedded image input ${path} participates in the app release`, t => {
    const f = fixture(t);
    f.git('tag', 'app-v1.2.3');
    f.commit('fix: update an embedded component', path);
    assert.equal(f.prepare().tag_name, 'app-v1.2.4');
  });
}

test('unrelated components, maintenance, and generated changelogs do not cause app releases', t => {
  const f = fixture(t);
  f.git('tag', 'app-v1.2.3');
  f.commit('feat: add a Babel feature', 'babel/lib/example.ex');
  f.commit('fix: repair the operator', 'infra/cloudflare-operator/main.go');
  f.commit('docs: regenerate changelog', 'app/CHANGELOG.md');
  f.commit('chore: bump a dependency');
  f.commit('ci: adjust release job');
  const release = f.prepare();
  assert.equal(release.should_release, 'false');
  assert.equal(release.build_version, '1.2.3');
  assert.equal(release.notes, '');
});

test('an empty first release is not fabricated', t => {
  const f = fixture(t);
  const release = f.prepare();
  assert.equal(release.should_release, 'false');
  assert.equal(release.build_version, '0.1.0');
});

test('rerunning the same released commit does not bump again', t => {
  const f = fixture(t);
  f.git('tag', 'app-v1.2.3');
  f.commit('fix: repair an app bug');
  f.git('tag', f.prepare().tag_name);
  const release = f.prepare();
  assert.equal(release.should_release, 'false');
  assert.equal(release.build_version, '1.2.4');
});

test('coalesced merges are cumulative and release notes omit already released changes', t => {
  const f = fixture(t);
  f.commit('feat: already released');
  f.git('tag', 'app-v1.2.3');
  f.commit('fix: first merge');
  f.commit('feat: second merge', 'ee/lib/new.ex');
  const release = f.prepare();
  assert.equal(release.tag_name, 'app-v1.3.0');
  assert.match(release.notes, /first merge/);
  assert.match(release.notes, /second merge/);
  assert.doesNotMatch(release.notes, /already released/);
});

test('a newer app tag on another branch cannot change this release version', t => {
  const f = fixture(t);
  f.git('tag', 'app-v1.2.3');
  f.git('checkout', '-b', 'other');
  f.commit('feat: unrelated branch');
  f.git('tag', 'app-v9.0.0');
  f.git('checkout', 'main');
  f.commit('fix: main branch bug');
  assert.equal(f.prepare().tag_name, 'app-v1.2.4');
});

test('git-cliff errors fail rather than silently skipping a release', t => {
  const f = fixture(t);
  writeFileSync(join(f.cwd, 'app/cliff.toml'), 'invalid config');
  const result = spawnSync('bash', [join(root, '.github/scripts/prepare-app-release.sh')], {
    cwd: f.cwd, env: { ...process.env, GITHUB_OUTPUT: join(f.cwd, '.git/outputs') },
  });
  assert.notEqual(result.status, 0);
});

function imageTags(t, edition, version = '') {
  const dir = mkdtempSync(join(tmpdir(), 'glossia-image-tags-'));
  t.after(() => rmSync(dir, { recursive: true, force: true }));
  const output = join(dir, 'outputs');
  run('bash', [join(root, '.github/scripts/app-image-tags.sh')], root, {
    EDITION: edition, VERSION: version, IMAGE: 'ghcr.io/glossia/glossia',
    REVISION: 'abc123', RUN_NUMBER: '42', GITHUB_OUTPUT: output,
  });
  const lines = readFileSync(output, 'utf8').trim().split('\n');
  assert.equal(lines.shift(), 'tags<<EOF');
  assert.equal(lines.pop(), 'EOF');
  return lines.map(line => line.replace('ghcr.io/glossia/glossia:', ''));
}

test('community releases have explicit tags and backwards-compatible core aliases', t => {
  const tags = imageTags(t, 'core', '1.2.3');
  assert.deepEqual(tags, [
    'abc123', 'main', 'main-42-abc123',
    'abc123-community', 'main-community', 'main-42-abc123-community',
    '1.2.3-community', 'latest-community', '1.2.3', 'latest',
  ]);
  assert.ok(tags.every(tag => !tag.includes('enterprise')));
});

test('enterprise releases cannot overwrite community tags', t => {
  const tags = imageTags(t, 'enterprise', '1.2.3');
  assert.deepEqual(tags, [
    'abc123-enterprise', 'main-enterprise', 'main-42-abc123-enterprise',
    '1.2.3-enterprise', 'latest-enterprise',
  ]);
  assert.ok(tags.every(tag => tag.endsWith('-enterprise')));
});

for (const edition of ['core', 'enterprise']) {
  test(`maintenance builds of ${edition} do not overwrite version or latest tags`, t => {
    assert.ok(imageTags(t, edition).every(tag => !tag.startsWith('latest') && !tag.startsWith('1.2.3')));
  });
}

test('release publication is serialized, waits for both editions, and pins the tested commit', () => {
  const workflow = read('.github/workflows/deploy.yml');
  assert.match(workflow, /group: release-app-main\s+cancel-in-progress: false/);
  assert.ok(workflow.includes("github.event.workflow_run.event == 'push'"));
  assert.ok(workflow.includes("github.event.workflow_run.head_repository.full_name == github.repository"));
  assert.ok(workflow.includes('git rev-parse origin/main'));
  assert.ok(workflow.includes('needs: [prepare, publish]'));
  assert.ok(workflow.includes("if: needs.prepare.outputs.should_release == 'true'"));
  assert.ok(workflow.includes('fail-fast: false'));
  assert.ok(workflow.includes('ref: ${{ github.event.workflow_run.head_sha }}'));
  assert.ok(workflow.includes('REVISION: ${{ github.event.workflow_run.head_sha }}'));
  assert.ok(workflow.includes('--target "$REVISION"'));
  assert.ok(workflow.includes('GLOSSIA_VERSION=${{ needs.prepare.outputs.build_version }}'));
  assert.doesNotMatch(workflow, /git push.*main/);
  assert.ok(read('app/mix.exs').includes('version: System.get_env("GLOSSIA_VERSION", "0.1.0")'));
  assert.match(read('app/Dockerfile'), /ARG GLOSSIA_VERSION=0\.1\.0\s+ENV GLOSSIA_VERSION=\$\{GLOSSIA_VERSION\}/);
});

test('embedded web and license changes trigger the post-merge checks and image pipeline', () => {
  const workflow = read('.github/workflows/app.yml');
  for (const path of ['sdk/web/**', 'LICENSE.md', 'LICENSE-APACHE', '.github/scripts/*app*.sh']) {
    assert.equal(workflow.split(`- "${path}"`).length - 1, 2, path);
  }
});
