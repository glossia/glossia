# Workflow runners

Glossia workflows use standard GitHub-hosted runners. New Linux jobs should use
`ubuntu-24.04`; native release builds keep their standard Linux, macOS, and
Windows matrix labels. Fork and same-repository pull requests use the same
hosted runner selection.

The repository is public, so standard hosted execution minutes are free under
[GitHub Actions billing](https://docs.github.com/en/billing/concepts/product-billing/github-actions).
Larger runners are billed even for public repositories, and artifact/cache
storage has separate allowances. Do not switch to self-hosted or larger runners
without reviewing the cost, security, and availability implications.

The management-cluster reconciliation job also runs on GitHub-hosted Linux.
Its certificate-authenticated public Kubernetes endpoint is documented in
[`infra/k8s/onboarding.md`](../infra/k8s/onboarding.md#a6-tailscale-on-the-mgmt-vm).
The job still runs only on main-branch pushes, uses the production environment,
and obtains its credentials through Infisical's existing identity federation.
Moving runners does not change those trust restrictions or expose credentials
to pull-request jobs.

The tests in `github-hosted-runners.test.cjs` check all workflow runner selectors,
including CLI release matrix entries. `license-checks.yml` runs them whenever
any workflow changes. Add newly supported standard runner labels to the explicit
allowlist only after checking GitHub's current runner documentation.

Already queued runs retain the workflow definition from their original commit.
A new commit starts the applicable pull-request checks with the new runner
selection; rerunning an old run does not migrate its jobs.
