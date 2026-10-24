const assert = require('node:assert/strict');
const { readFileSync } = require('node:fs');
const { test } = require('node:test');

// Exercise the exact privileged script, not a second implementation of it.
const workflow = readFileSync(new URL('../workflows/enterprise-cla.yml', `file://${__filename}`), 'utf8');
const script = workflow.split('          script: |\n')[1].split('\n      - name:')[0]
  .split('\n').map(line => line.replace(/^ {12}/, '')).join('\n');
const run = new (Object.getPrototypeOf(async function () {}).constructor)('github', 'context', 'core', script);

const statement = 'I have read the Glossia Enterprise CLA, Version 2, and I hereby sign it for my contributions to ee/.';
const agreementText = '# Glossia Enterprise Contributor License Agreement\n\nVersion 2, October 24, 2026.\n\nFinal reviewed agreement.\n';
const agreement = {
  version: 2, sha: 'document-blob-sha',
  url: 'https://github.com/glossia/glossia/blob/trusted-base/CLA.md',
  statement, text: agreementText,
};
const documentResponse = () => ({ data: {
  sha: agreement.sha, content: Buffer.from(agreementText).toString('base64'),
} });
const storageResponse = (record = { agreement, signedContributors: [] }) => ({ data: {
  content: Buffer.from(JSON.stringify(record)).toString('base64'),
} });

function fixture(files, overrides = {}) {
  const calls = [];
  const output = {};
  const pr = { state: 'open', user: { id: 1 }, head: { sha: 'head-sha' }, changed_files: files.length, commits: 1, ...overrides };
  const commits = [{ sha: 'head-sha', author: { id: 1, login: 'contributor' }, committer: { id: 1, login: 'contributor' }, commit: { verification: { verified: true } } }];
  const github = {
    rest: {
      pulls: {
        get: async args => { calls.push(['pull', args]); return { data: pr }; },
        listFiles: Symbol('listFiles'),
        listCommits: Symbol('listCommits'),
      },
      git: {
        getRef: async args => { calls.push(['ref', args]); return { data: { object: { sha: 'trusted-base' } } }; },
        createRef: async args => { calls.push(['create', args]); },
      },
      repos: {
        get: async () => ({ data: { default_branch: 'main' } }),
        getContent: async args => {
          calls.push(['content', args]);
          return args.path === 'CLA.md' ? documentResponse() : storageResponse();
        },
        createOrUpdateFileContents: async args => { calls.push(['initialize', args]); },
      },
    },
    paginate: async (method, args) => {
      assert.equal(args.per_page, 100);
      if (method === github.rest.pulls.listCommits) return commits;
      assert.equal(method, github.rest.pulls.listFiles);
      calls.push(['files', args]);
      return files;
    },
  };
  const context = {
    repo: { owner: 'glossia', repo: 'glossia' },
    payload: { pull_request: { number: 42, head: { sha: 'head-sha' } } },
    issue: { number: 42 },
  };
  const core = { setOutput: (key, value) => { output[key] = value; }, info: () => {} };
  return { github, context, core, output, calls, commits, pr, execute: () => run(github, context, core) };
}

test('core-only changes do not request signatures or touch storage', async () => {
  const f = fixture([{ filename: 'app/lib/glossia/events.ex' }, { filename: 'CLA.md' }]);
  await f.execute();
  assert.equal(f.output.required, 'false');
  assert.equal(f.calls.some(([name]) => name === 'ref'), false);
});

for (const status of ['added', 'modified', 'removed']) {
  test(`${status} enterprise files require signatures`, async () => {
    const f = fixture([{ filename: 'ee/lib/audit.ex', status }]);
    await f.execute();
    assert.equal(f.output.required, 'true');
  });
}

test('renames out of ee still require signatures', async () => {
  const f = fixture([{ filename: 'app/lib/audit.ex', previous_filename: 'ee/lib/audit.ex', status: 'renamed' }]);
  await f.execute();
  assert.equal(f.output.required, 'true');
});

test('similar prefixes do not require signatures', async () => {
  const f = fixture([{ filename: 'ee-notes.md' }, { filename: 'app/ee/audit.ex' }]);
  await f.execute();
  assert.equal(f.output.required, 'false');
});

test('enterprise files after the first API page are checked', async () => {
  const f = fixture([...Array.from({ length: 150 }, (_, i) => ({ filename: `app/${i}.ex` })), { filename: 'ee/audit.ex' }]);
  await f.execute();
  assert.equal(f.output.required, 'true');
});

test('truncated file lists fail closed', async () => {
  const f = fixture([{ filename: 'app/a.ex' }], { changed_files: 3001 });
  await assert.rejects(f.execute, /complete diff/);
});

test('enterprise PRs exceeding the action commit limit fail closed', async () => {
  const f = fixture([{ filename: 'ee/audit.ex' }], { commits: 101 });
  await assert.rejects(f.execute, /at most 100 commits/);
});

test('large core-only PRs still need no CLA', async () => {
  const f = fixture([{ filename: 'app/a.ex' }], { commits: 101 });
  await f.execute();
  assert.equal(f.output.required, 'false');
});

test('comment events resolve the PR through the API', async () => {
  const f = fixture([{ filename: 'ee/audit.ex' }]);
  f.context.payload = { issue: { number: 42, pull_request: {} } };
  await f.execute();
  assert.equal(f.calls[0][1].pull_number, 42);
  assert.equal(f.output.required, 'true');
});

test('comments on closed PRs do not collect signatures', async () => {
  const f = fixture([{ filename: 'ee/audit.ex' }], { state: 'closed' });
  await f.execute();
  assert.equal(f.output.required, 'false');
  assert.deepEqual(f.calls.map(([name]) => name), ['pull']);
});

test('first use creates storage from the trusted default branch', async () => {
  const f = fixture([{ filename: 'ee/audit.ex' }]);
  f.github.rest.git.getRef = async args => {
    if (args.ref === 'heads/cla-signatures') throw Object.assign(new Error('missing'), { status: 404 });
    assert.equal(args.ref, 'heads/main');
    return { data: { object: { sha: 'trusted-base' } } };
  };
  await f.execute();
  assert.deepEqual(f.calls.find(([name]) => name === 'create')[1], {
    owner: 'glossia', repo: 'glossia', ref: 'refs/heads/cla-signatures', sha: 'trusted-base',
  });
});

test('concurrent first-use branch creation is safe', async () => {
  const f = fixture([{ filename: 'ee/audit.ex' }]);
  let calls = 0;
  let signatureReads = 0;
  f.github.rest.git.getRef = async args => {
    calls++;
    if (args.ref === 'heads/cla-signatures' && signatureReads++ === 0) {
      throw Object.assign(new Error('missing'), { status: 404 });
    }
    return { data: { object: { sha: 'trusted-base' } } };
  };
  f.github.rest.git.createRef = async () => { throw Object.assign(new Error('exists'), { status: 422 }); };
  await f.execute();
  assert.equal(calls, 3);
});

test('API authorization failures are not treated as missing storage', async () => {
  const f = fixture([{ filename: 'ee/audit.ex' }]);
  f.github.rest.git.getRef = async () => { throw Object.assign(new Error('forbidden'), { status: 403 }); };
  await assert.rejects(f.execute, /forbidden/);
});

test('missing signature file is initialized with the action schema', async () => {
  const f = fixture([{ filename: 'ee/audit.ex' }]);
  f.github.rest.repos.getContent = async args => {
    if (args.path === 'CLA.md') return documentResponse();
    throw Object.assign(new Error('missing'), { status: 404 });
  };
  await f.execute();
  const args = f.calls.find(([name]) => name === 'initialize')[1];
  assert.equal(args.branch, 'cla-signatures');
  assert.equal(args.path, 'signatures/v2/cla.json');
  assert.deepEqual(JSON.parse(Buffer.from(args.content, 'base64').toString()), { agreement, signedContributors: [] });
  assert.equal(f.output['document-url'], agreement.url);
});

test('concurrent signature-file creation verifies the existing file', async () => {
  const f = fixture([{ filename: 'ee/audit.ex' }]);
  let reads = 0;
  f.github.rest.repos.getContent = async args => {
    if (args.path === 'CLA.md') return documentResponse();
    if (reads++ === 0) throw Object.assign(new Error('missing'), { status: 404 });
    return storageResponse();
  };
  f.github.rest.repos.createOrUpdateFileContents = async () => { throw Object.assign(new Error('conflict'), { status: 409 }); };
  await f.execute();
  assert.equal(reads, 2);
});

test('signature-file authorization failures fail closed', async () => {
  const f = fixture([{ filename: 'ee/audit.ex' }]);
  f.github.rest.repos.getContent = async args => {
    if (args.path === 'CLA.md') return documentResponse();
    throw Object.assign(new Error('forbidden'), { status: 403 });
  };
  await assert.rejects(f.execute, /forbidden/);
});

test('a stale target event fails even if the current diff is core-only', async () => {
  const f = fixture([{ filename: 'app/a.ex' }]);
  f.context.payload.pull_request.head.sha = 'old-sha';
  await assert.rejects(f.execute, /head changed/);
});

test('a head change while listing files fails closed', async () => {
  const f = fixture([{ filename: 'app/a.ex' }]);
  let reads = 0;
  f.github.rest.pulls.get = async () => ({ data: {
    state: 'open', changed_files: 1, head: { sha: reads++ === 0 ? 'head-sha' : 'new-sha' },
  } });
  await assert.rejects(f.execute, /head changed while inspecting/);
});

test('unlinked authors cannot inherit a signing committer identity', async () => {
  const f = fixture([{ filename: 'ee/audit.ex' }]);
  f.commits[0].author = null;
  await assert.rejects(f.execute, /unlinked author/);
});

test('an unlinked author cannot hide behind a matching git author name', async () => {
  const f = fixture([{ filename: 'ee/audit.ex' }], { commits: 2 });
  f.commits.unshift({ sha: 'unsigned', author: null, commit: { author: { name: 'contributor' }, verification: { verified: true } }, committer: { id: 1, login: 'contributor' } });
  await assert.rejects(f.execute, /unlinked author/);
});

test('different author and committer identities fail closed', async () => {
  const f = fixture([{ filename: 'ee/audit.ex' }]);
  f.commits[0].committer = { id: 2, login: 'other' };
  await assert.rejects(f.execute, /different author and committer/);
});

test('an unlinked committer fails closed', async () => {
  const f = fixture([{ filename: 'ee/audit.ex' }]);
  f.commits[0].committer = null;
  await assert.rejects(f.execute, /different author and committer/);
});

test('GitHub web-flow commits retain the linked author identity', async () => {
  const f = fixture([{ filename: 'ee/audit.ex' }]);
  f.commits[0].committer = { id: 19864447, login: 'web-flow' };
  await f.execute();
  assert.equal(f.output.required, 'true');
});

test('a truncated commit list fails closed', async () => {
  const f = fixture([{ filename: 'ee/audit.ex' }], { commits: 2 });
  await assert.rejects(f.execute, /complete commit list/);
});

test('a commit list for a different head fails closed', async () => {
  const f = fixture([{ filename: 'ee/audit.ex' }]);
  f.commits[0].sha = 'old-head';
  await assert.rejects(f.execute, /complete commit list/);
});

test('unsigned commits cannot impersonate a previously signed human identity', async () => {
  const f = fixture([{ filename: 'ee/audit.ex' }]);
  f.commits[0].commit.verification.verified = false;
  await assert.rejects(f.execute, /lacks a verified signature/);
});

test('missing verification data cannot impersonate a previously signed identity', async () => {
  const f = fixture([{ filename: 'ee/audit.ex' }]);
  delete f.commits[0].commit;
  await assert.rejects(f.execute, /lacks a verified signature/);
});

for (const id of [41898282, 49699333]) {
  test(`a human PR cannot bypass signing with exempt bot identity ${id}`, async () => {
    const f = fixture([{ filename: 'ee/audit.ex' }]);
    f.commits[0].author = { id };
    f.commits[0].committer = { id };
    await assert.rejects(f.execute, /impersonates an exempt bot/);
  });
}

test('a bot exemption requires a verified commit in that bot own PR', async () => {
  const f = fixture([{ filename: 'ee/audit.ex' }], { user: { id: 49699333 } });
  f.commits[0].author = { id: 49699333, login: 'dependabot[bot]' };
  f.commits[0].committer = f.commits[0].author;
  await f.execute();
  assert.equal(f.output.required, 'true');
});

test('verified owner-only contributions require no inbound grant or finalized agreement', async () => {
  const f = fixture([{ filename: 'ee/audit.ex' }]);
  f.commits[0].author = { id: 663605, login: 'pepicrft' };
  f.commits[0].committer = f.commits[0].author;
  f.github.rest.repos.getContent = async () => { throw new Error('must not read a CLA for owner-only work'); };
  await f.execute();
  assert.equal(f.output.required, 'false');
});

test('an unsigned commit cannot impersonate the exempt owner', async () => {
  const f = fixture([{ filename: 'ee/audit.ex' }]);
  f.commits[0].author = { id: 663605, login: 'pepicrft' };
  f.commits[0].committer = f.commits[0].author;
  f.commits[0].commit.verification.verified = false;
  await assert.rejects(f.execute, /lacks a verified signature/);
});

test('draft agreements do not collect signatures', async () => {
  const f = fixture([{ filename: 'ee/audit.ex' }]);
  f.github.rest.repos.getContent = async () => ({ data: {
    content: Buffer.from(`${agreementText}\nDraft pending legal review.`).toString('base64'),
  } });
  await assert.rejects(f.execute, /complete legal review/);
  assert.equal(f.calls.some(([name]) => name === 'initialize'), false);
});

test('changed agreements cannot reuse previous signatures', async () => {
  const f = fixture([{ filename: 'ee/audit.ex' }]);
  f.github.rest.repos.getContent = async args => args.path === 'CLA.md'
    ? documentResponse()
    : storageResponse({ agreement: { ...agreement, sha: 'previous-blob' }, signedContributors: [{ id: 1 }] });
  await assert.rejects(f.execute, /changed without a new signature version/);
});

test('an immutable agreement permalink survives later commits with unchanged terms', async () => {
  const f = fixture([{ filename: 'ee/audit.ex' }]);
  f.github.rest.repos.getContent = async args => args.path === 'CLA.md'
    ? documentResponse()
    : storageResponse({ agreement: { ...agreement, url: 'https://github.com/glossia/glossia/blob/older-commit/CLA.md' }, signedContributors: [] });
  await f.execute();
  assert.equal(f.output['document-url'], 'https://github.com/glossia/glossia/blob/older-commit/CLA.md');
});

test('the agreement, signing instructions, and storage version stay aligned', () => {
  const cla = readFileSync(new URL('../../CLA.md', `file://${__filename}`), 'utf8');
  const contributing = readFileSync(new URL('../../CONTRIBUTING.md', `file://${__filename}`), 'utf8');
  const version = cla.match(/^Version (\d+),/m)[1];
  assert.equal(version, '2');
  assert.ok(cla.includes(statement));
  assert.ok(contributing.includes(statement));
  assert.equal(workflow.split(statement).length - 1, 3);
  assert.match(workflow, new RegExp(`path-to-signatures: signatures/v${version}/cla\\.json`));
});

test('privileged workflow never checks out contribution code and pins actions', () => {
  assert.doesNotMatch(workflow, /actions\/checkout|secrets\.PERSONAL_ACCESS_TOKEN/);
  for (const [, ref] of workflow.matchAll(/uses: [^@]+@([^\s]+)/g)) {
    assert.match(ref, /^[a-f0-9]{40}$/);
  }
  assert.match(workflow, /path-to-signatures: signatures\/v2\/cla\.json/);
});
