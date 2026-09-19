# Babel

Babel is Glossia's internal operations platform.

## Local development

From the repository root:

```bash
mise install
mix phx.server
```

## Repository layout

- Application source: root (`lib/`, `config/`, `priv/`, `test/`, `Dockerfile`, `mix.exs`).
- Helm chart: `chart/` — installable on any Kubernetes cluster.
- Flux manifests: `flux/` — cluster-side gitops resources that reconcile the chart from this repo.
- CI + image publish workflows: `.github/workflows/ci.yml` and `publish.yml`.

## Continuous deployment

Every push to `main` follows this loop:

1. `.github/workflows/ci.yml` builds, tests, and lints the app on pull requests and pushes.
2. On a successful CI run against `main`, `.github/workflows/publish.yml` builds the container image and pushes it to `ghcr.io/glossia/babel` with three tags: the commit SHA, `main`, and a run-numbered tag. The image carries `org.opencontainers.image.source` pointing at this repository.
3. The same workflow rewrites `chart/values-production.yaml`'s `image.tag` to the SHA and commits back to `main` as `chore(deploy): update babel image to <sha>`.
4. Flux on the Glossia mgmt cluster watches this repository via the `flux-system/babel` GitRepository, sees the new revision, and reconciles the `org-glossia/babel` HelmRelease.
5. Flux's helm-controller runs `helm upgrade` against the workload cluster (via the `glossia-production-kubeconfig` Secret referenced in the HelmRelease) which rolls the `babel` Deployment in the `babel` namespace forward.

`.github/workflows/publish.yml` needs a repository secret named `GHCR_PUSH_TOKEN` — a PAT with `write:packages` scope — because the default `GITHUB_TOKEN` on this repository is restricted to `read` by the organization policy.

### Cluster setup

The Flux setup on the mgmt cluster is applied once, out of band:

```bash
KUBECONFIG=~/.kube/glossia-mgmt.yaml kubectl apply -k flux/
```

`flux/git-repository.yaml` reuses the shared `flux-system` GitHub App credentials (installation-wide access on the glossia org), so no additional deploy key is required. The HelmRelease uses `kubeConfig.secretRef.glossia-production-kubeconfig` to reach the workload cluster.

Both manifests carry `kustomize.toolkit.fluxcd.io/reconcile: disabled` so nothing else on the mgmt cluster reverts them.

Confirm reconciliation with:

```bash
KUBECONFIG=~/.kube/glossia-mgmt.yaml flux get sources git -n flux-system babel
KUBECONFIG=~/.kube/glossia-mgmt.yaml flux get helmreleases -n org-glossia babel
KUBECONFIG=~/.kube/glossia-production.yaml kubectl -n babel rollout status deploy/babel
```

## Worktree-aware development

The development and test PostgreSQL database names, as well as the server
ports, use the stable suffix assigned to the current Git worktree. This allows
each checkout to run Babel independently without colliding with Glossia or
another Babel checkout.

The environment is loaded automatically by `mise`. The relevant values are:

- `BABEL_POSTGRES_DB` for the development database.
- `BABEL_TEST_POSTGRES_DB` for the test database.
- `BABEL_SERVER_PORT` for the development server.
- `BABEL_TEST_PORT` for the test server.

After starting the server, visit `http://localhost:${BABEL_SERVER_PORT}`. When
the environment is not loaded, Babel falls back to port `4060` and the
`babel_dev` database.

## Glossia production data

Babel reaches Glossia through a cluster-only
[Transport Layer Security](https://en.wikipedia.org/wiki/Transport_Layer_Security)
listener, not through a production PostgreSQL connection. The listener has no
ingress route, only Babel can reach its service port, and Glossia rejects this
endpoint on its public listener before authentication is attempted. Each Babel
pod receives a short-lived Kubernetes service-account token with the
`glossia-internal` audience. Glossia verifies the token as a
[JSON Web Token](https://jwt.io/introduction) against the production
[JSON Web Key Set](https://datatracker.ietf.org/doc/html/rfc7517), then checks
the issuer, audience, namespace, service-account name, and lifetime.

The database request is constrained in three layers:

- Only `SELECT`, `WITH`, `EXPLAIN`, and `SHOW` statements are accepted.
- The statement runs in a read-only transaction with a five-second timeout and
  a 200-row response limit.
- Glossia switches to the non-login `glossia_babel_ro` PostgreSQL role, which
  inherits PostgreSQL's
  [`pg_read_all_data`](https://www.postgresql.org/docs/current/predefined-roles.html)
role and has no write permission.
- ClickHouse requests use a separate restricted account that has `SELECT` only
  on the Glossia analytics database. Its server-side profile fixes execution,
  result, memory, and concurrency limits; Babel never receives its password.

The same private listener has two narrow mutation endpoints for claimable
organizations. They can create a public ownerless organization and assign it
to an existing Glossia user. Those operations are initiated only from Babel's
[Pomerium](https://www.pomerium.com/) protected operations surface, include the
authenticated operator identity in the audit event, and remain unavailable on
the public Glossia listener.

To verify the deployed connection, run this from an authenticated cluster
terminal:

```bash
kubectl -n babel exec deploy/babel -c web -- \
  /app/bin/babel eval 'IO.inspect(Babel.Glossia.query("SELECT 1 AS connection_ok"))'
```

To query ClickHouse analytics through the same private listener:

```bash
kubectl -n babel exec deploy/babel -c web -- \
  /app/bin/babel eval 'IO.inspect(Babel.Glossia.clickhouse_query("SELECT count() AS events FROM analytics_events"))'
```
