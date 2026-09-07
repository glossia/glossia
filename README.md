# Glossia 🌍

Glossia is an open source language OS. It brings your voice, terminology, and
tone together so linguists and product teams can shape how your organization
communicates across every language and surface.

The source is available under the [O'Saasy License](./LICENSE.md): you can
self-host, modify, and redistribute it, but you can't offer it to third
parties as a competing hosted or SaaS product.

## Self-hosting

Glossia is designed to run on your own infrastructure. The `deploy/` directory
contains a Helm chart you can install on any Kubernetes cluster. See
[Self-host Glossia](https://glossia.ai/docs/how-to/self-host-glossia) for a
walkthrough.

## Repository layout

- `app/` contains the Glossia web application.
- `cli/`, `sdk/`, and `mobile/` contain the client software.
- `deploy/` contains the application Helm chart.
