# L10N Standard

This repository packages three things:

- A human-first `L10N.md` standard for translation context files.
- Versioned JSON Schemas for the supported document shapes.
- An Eleventy site that explains the convention and shows working examples.

## Commands

```bash
mise run install
mise run validate
mise run dev
mise run build
```

## Deployment

The site builds into `_site` and is deployed to Kubernetes as an immutable
Caddy image. The production workflow builds the image from `l10n/Dockerfile`,
pushes it to GHCR, and upgrades the standalone `deploy/helm/l10n` chart.

```bash
docker build -t l10n-site .
helm template l10n ../deploy/helm/l10n \
  --values ../deploy/values-l10n-production.yaml
```

## Layout

```text
L10N.md
examples/
schemas/
scripts/
site/
```
