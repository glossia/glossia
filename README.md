# Glossia

Glossia is the language operating system for your organization. It brings your
voice, terminology, and tone together so linguists and product teams can shape
how your organization communicates across every language and surface.

## Get started

Visit [glossia.ai](https://glossia.ai) to learn more and read the
[documentation](https://glossia.ai/docs).

To run the web application locally:

```bash
cd app
mise run install
mix phx.server
```

To initialize a repository, install Glossia with
[mise](https://mise.jdx.dev/) and run:

```bash
mise exec -- glossia init
```

The command-line interface only initializes the repository configuration.
Translation runs on the Glossia server after the repository is connected.

## License

Glossia is licensed under the [Mozilla Public License 2.0](LICENSE).
The [Glossia trademarks](TRADEMARKS.md) are not licensed under that grant.

## Release tags

Release tags identify the component they version:

| Component | Tag format | Current distribution |
| --- | --- | --- |
| Command-line interface | `cli-vX.Y.Z` | GitHub Release assets |
| Web software development kit | `sdk-vX.Y.Z` | npm and GitHub Release |
| Mobile app | `mobile-vX.Y.Z` | Reserved for future mobile releases |
| Server | `server-vX.Y.Z` | Reserved for future server releases |

Until server releases are versioned, production images use immutable commit
tags and the moving `main` tag in the GitHub Container Registry.

## Contributing

Read [CONTRIBUTING.md](CONTRIBUTING.md) before opening an issue or pull
request. Security vulnerabilities should be reported according to
[SECURITY.md](SECURITY.md), not through a public issue.
