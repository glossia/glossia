# Glossia 🌍

Glossia is the language operating system for your organization. It brings your
voice, terminology, and tone together so linguists and product teams can shape
how your organization communicates across every language and surface.

## Get started 🚀

Visit [glossia.ai](https://glossia.ai) to learn more and read the
[documentation](https://glossia.ai/docs).

To initialize a repository, install Glossia with
[mise](https://mise.jdx.dev/) and run:

```bash
mise exec -- glossia init
```

The command-line interface only initializes the repository configuration.
Translation runs on the Glossia server after the repository is connected.

## Release tags 🏷️

Release tags identify the component they version:

| Component | Tag format | Current distribution |
| --- | --- | --- |
| Command-line interface | `cli-vX.Y.Z` | GitHub Release assets |
| Web software development kit | `sdk-vX.Y.Z` | npm and GitHub Release |
| Mobile app | `mobile-vX.Y.Z` | Reserved for future mobile releases |
| Server | `server-vX.Y.Z` | Reserved for future server releases |

Until server releases are versioned, production images use immutable commit
tags and the moving `main` tag in the GitHub Container Registry.

## Repository layout

- `app/` contains the Glossia web application.
- `cli/`, `sdk/`, and `mobile/` contain the client software.
- `deploy/` contains the application Helm chart.
- `ops/` contains production infrastructure and deployment configuration.
