# Glossia Discourse forum

This chart deploys the production forum at `community.glossia.ai`. It uses the
official Discourse web-only image with dedicated PostgreSQL and Redis services,
the shared cluster mail relay, and the existing ingress and certificate
controllers. The PostgreSQL image stays on major version 15 to match Discourse
and includes the vector extension required by the bundled artificial-intelligence
plugin.

The production release is reconciled from
`infra/k8s/workload-apps/glossia-production/discourse-helmrelease.yaml`. Before
the first reconciliation, create independent random values named
`DISCOURSE_DB_PASSWORD` and `DISCOURSE_REDIS_PASSWORD` under `/kubernetes` in
Infisical. The chart reuses `MAIL_RELAY_USERNAME` and `MAIL_RELAY_PASSWORD` from
that folder.

The PostgreSQL database is backed up daily to the existing off-cluster database
backup bucket under `community-production/postgres`. The `/shared` volume keeps
uploads, local forum backups, and application logs and carries a Helm retention
annotation so removing the release does not remove that claim.

Render the production configuration locally with:

```bash
helm lint infra/helm/discourse \
  --values infra/helm/discourse/values-production.yaml

helm template community infra/helm/discourse \
  --namespace community \
  --values infra/helm/discourse/values-production.yaml
```
