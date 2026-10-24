const assert = require('node:assert/strict');
const { readFileSync } = require('node:fs');
const { test } = require('node:test');

const root = new URL('../../', `file://${__filename}`);
const read = path => readFileSync(new URL(path, root), 'utf8');

test('publication distinguishes core defaults from explicitly tagged enterprise images', () => {
  const workflow = read('.github/workflows/deploy.yml');
  assert.match(workflow, /edition: core\s+suffix: ""\s+licenses: Apache-2\.0/);
  assert.match(workflow, /edition: enterprise\s+suffix: -enterprise/);
  assert.ok(workflow.includes('GLOSSIA_EDITION=${{ matrix.edition }}'));
  assert.ok(workflow.includes(':main${{ matrix.suffix }}'));
  assert.ok(workflow.includes('group: publish-production-image-${{ matrix.edition }}'));
});

test('the public chart defaults to core while production explicitly selects enterprise', () => {
  assert.match(read('deploy/helm/glossia/values.yaml'), /image:\s+repository: ghcr\.io\/glossia\/glossia\s+tag: main\s/);
  assert.match(read('infra/k8s/workload-apps/glossia-production/glossia-helmrelease.yaml'), /tag: main-enterprise #/);
  assert.match(read('infra/k8s/mgmt/flux/glossia-image-automation.yaml'), /pattern: "\^main-enterprise\$"/);
});

test('core Docker stages do not require or copy enterprise sources', () => {
  const dockerfile = read('app/Dockerfile');
  assert.match(dockerfile, /ARG GLOSSIA_EDITION=core/);
  assert.match(dockerfile, /FROM source-\$\{GLOSSIA_EDITION\} AS edition-source/);
  const enterpriseStage = dockerfile.split('FROM source-core AS source-enterprise')[1].split('FROM source-${GLOSSIA_EDITION}')[0];
  const eeCopies = dockerfile.match(/^COPY --from=ee .*$/gm);
  assert.equal(eeCopies.length, 2);
  for (const copy of eeCopies) assert.ok(enterpriseStage.includes(copy));
  assert.match(dockerfile, /COPY --from=edition-source \/ee \/ee/);
  assert.match(dockerfile, /COPY --from=edition-source \/enterprise-licenses/);
});

test('enterprise source redistribution preserves the ability to copy the source repository', () => {
  const license = read('ee/LICENSE.md');
  assert.match(license, /You may redistribute the Enterprise Software in source form/);
  assert.match(license, /Removing `ee\/` leaves the Apache-2\.0 core/);
});
