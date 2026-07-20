---
name: glossia-infra-review
description: Project-specific PR-review rules for Glossia infrastructure under `infra/`, `deploy/`, and `.github/workflows/`. Focuses on what only this repo knows — the lean Hetzner k8s shape, Helm values/templates split, Terraform's kube-hetzner module, ClickHouse backup posture, and the Postgres autoscaling baseline.
---

# Glossia Infra Review

This skill is intentionally narrow. **Generic YAML / HCL style and
formatting is already covered by `yamllint` / `terraform fmt` — do
not flag those.** Focus on the rules below; they catch configuration
mistakes that would only surface in production.

For each finding, cite `path:line` and quote the relevant snippet.

---

## 1. Helm — chart structure under `infra/helm/platform`

The platform chart layout is `Chart.yaml` + `values.yaml` (defaults)
+ `values-hetzner.yaml` (environment override) + `templates/`.
Environment-specific overrides live in `values-<env>.yaml`, not in
the templates themselves.

### Flag (Severity: medium)

- A template under `infra/helm/platform/templates/` that hard-codes
  an environment-specific value (hostname, replica count, secret name,
  storage class) instead of consuming a `.Values.*` field that
  `values-hetzner.yaml` overrides.
- A new value added to `values.yaml` without a sane default, or
  added to `values-hetzner.yaml` without the corresponding key in
  `values.yaml` (drift between defaults and the env override).
- A `values-*.yaml` file that sets secrets in plaintext. Secrets must
  flow through external-secrets / sealed-secrets, not the chart values.

### Do not flag

- Pre-existing template / values divergence unchanged by the diff.

---

## 2. Storage — Postgres autoscaling is the baseline

The production Postgres tier has storage autoscaling configured
(see commit `c39f6a0`). A change that removes the autoscaling
annotations/spec without an explicit "moving to fixed disk" rationale
is almost certainly a regression.

### Flag (Severity: high)

- A Helm template or values change that removes Postgres storage
  autoscaling without a PR description note explaining why.
- A new Postgres-adjacent workload that sets a fixed `resources.requests.storage`
  far below the autoscale floor.

---

## 3. ClickHouse — backup posture

ClickHouse backups are configured with the RBAC capture explicitly
disabled (see commit `63e2250`). Re-enabling RBAC capture without
context is likely a copy-paste regression.

### Flag (Severity: medium)

- A ClickHouse backup spec / values change that re-enables RBAC
  capture without a PR description note explaining the new
  requirement.
- A new backup target bucket configured without versioning or
  lifecycle rules surfaced in the values file.

---

## 4. Kubernetes manifests — no `latest` tags, no `:` without digest in prod

### Flag (Severity: high)

- A workload manifest under `infra/k8s/` or a Helm template that uses
  an image tag of `latest`, `main`, or a moving floating tag for a
  production workload.
- A `image:` line without a tag at all.

### Flag (Severity: medium)

- A new `Deployment` / `StatefulSet` without resource requests
  configured. Hetzner nodes are sized assuming workloads declare
  requests.
- A new `Service` of type `LoadBalancer` without the Hetzner Cloud
  Controller Manager annotations the rest of the chart uses.

### Do not flag

- Existing image references unchanged by the diff.
- Manifests under `infra/k8s/mgmt/` for one-off cluster bootstrap
  tasks.

---

## 5. Terraform — kube-hetzner module pinning

`infra/terraform/hetzner/main.tf` consumes the `kube-hetzner` module.
Module sources must be pinned to a tag/sha; floating refs make
plan/apply non-reproducible.

### Flag (Severity: high)

- A `module "..." { source = "..." }` block in `infra/terraform/`
  without a `version = "..."` (for registry modules) or a `ref=<sha>`
  pin (for git-sourced modules).
- A `provider "..." { ... }` block missing a `required_providers`
  version pin in `versions.tf`.

### Flag (Severity: medium)

- A variable added to `variables.tf` without a `type` and `description`.
- A new resource that should be in `terraform.tfvars.example` but is
  missing.

---

## 6. Secrets — never plaintext in git

### Flag (Severity: critical)

- A plaintext credential (API key, password, private key, OAuth secret,
  DB connection string with embedded password) added to any file under
  `infra/`, `deploy/`, or `.github/workflows/`. Even
  base64-encoded `Secret` manifests must come from
  external-secrets / sealed-secrets, not committed plaintext.

### Flag (Severity: high)

- A workflow that prints `${{ secrets.* }}` to logs, writes them to a
  file checked into a build artifact, or passes them on the command
  line where they'd appear in `ps` output.

---

## 7. GitHub Actions — pinned actions, least privilege

### Flag (Severity: high)

- A new `uses: third-party/action@<floating>` (a moving tag like
  `@v1`, `@main`) without a commit SHA pin for any action that runs
  with write permissions or has access to repo secrets.
- A workflow with `permissions: write-all` or no `permissions:` block
  when sibling workflows declare a least-privilege set.

### Flag (Severity: medium)

- A new workflow without a `concurrency:` group when sibling
  workflows for the same surface use one (avoids overlapping deploy
  runs).

---

## Out of scope (handled elsewhere — do not flag)

- YAML / HCL indentation and quoting style → `yamllint` /
  `terraform fmt`.
- Helm template whitespace (`-}}` vs `}}`) unless it changes rendered
  output.
- Comments / TODOs / formatting-only diffs.

---

## Before submitting findings

For each finding, confirm:

1. The `path:line` is real and the snippet appears in the diff.
2. The category above is one of 1–7; if it isn't, downgrade to
   `uncertain: ...`.
3. Severity is set: **critical** (committed secrets), **high** (likely
   production regression), **medium** (convention gap), **low**
   (nice-to-have).
4. **The convention you are enforcing exists in the diff base.** If
   sibling manifests / modules don't follow the rule yet, the new
   code is consistent, not a regression. Downgrade to `uncertain: ...`.
   Security findings (rules 6, 7) and known-good defaults (rules 2, 3)
   apply regardless of base-state.
