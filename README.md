# Glossia 🌍

**A language OS for teams that ship continuously.**

Glossia brings voice, terminology, translation, revision history, and localization
analytics together so developers, linguists, and product teams can shape how
an organization communicates across languages and surfaces.

The goal is not just to generate a translation. It is to keep language work in
the same versioned, reviewable delivery loop as the product, with content owned
by the team rather than trapped in a separate editing workspace.

[Website](https://glossia.ai) · [Documentation](https://glossia.ai/docs) ·
[Community](https://community.glossia.ai) · [Contributing](CONTRIBUTING.md)

## Why Glossia

A product changes continuously. Its documentation, UI strings, and marketing
content need to change with it. Exporting content to a separate translation
workspace, editing it there, and importing it later can leave language versions
out of step with the source.

LLMs make useful drafts possible, but a prompt alone does not provide shared
terminology, change detection, validation, failure recovery, or a review history.
Glossia supplies that surrounding system.

Our guiding ideas are:

- **Keep content with the product.** Source files, localization configuration,
  and translated outputs belong in the repository. Proposed changes can be
  reviewed through pull requests and published through the existing pipeline.
- **Remember language decisions, not just matching sentences.** Voice guidance
  and glossaries give humans and agents reusable context for new writing as
  well as translation. Reviewed translation memories can still be useful;
  they should not be the only authority for a company's language knowledge.
- **Refine progressively.** Avoid redundant work on unchanged content, validate
  transformations, expose failures, and retain the human review boundary.
- **Make the system inspectable.** The application, CLI, SDK, and infrastructure
  live here so teams can understand how the workflow operates.

Read [Why Glossia](https://glossia.ai/docs/explanation/why-glossia),
[Continuous localization](https://glossia.ai/docs/explanation/continuous-localization),
and [Content ownership](https://glossia.ai/docs/explanation/content-ownership)
for the rationale and its limitations.

## What you can do

### Localize repository content

Connect a repository, configure an account model, and describe the source
language, files, and target languages in `L10N.md`. Automated project setup can
propose the initial configuration in a pull request. Translation runs happen
server-side, with progress and failures visible in the application and outputs
returned for repository review.

Bring your own provider API tokens for supported models. Account-scoped model
handles keep those credentials out of source control and let you change the
model behind a handle without rewriting every repository.

Content hashes and translation lockfiles help identify work that needs updating.
Reuse your repository's validation scripts, parsers, compilers, or documentation
checks through `L10N.md`, so a translation must satisfy the project's own
structural requirements before acceptance. Validation and bounded recovery surround
generation. An optional decision model can assess complete translations and request
corrections. Automated assessments
are model judgments, not a substitute for bilingual review.

### Maintain shared language context

Manage organizational voice, glossary terms, and language decisions in one
place. Reuse that context across projects and make it available to people and
agents rather than reconstructing it in every prompt. Revision history helps
teams understand how their guidance changes over time.

### Integrate existing tools and agents

Glossia exposes an OAuth-authenticated MCP server and REST interfaces. Use them
to bring language context into existing workflows. The Rust CLI can create a
starter `L10N.md` with `glossia init`; it is not a local translation engine.
See the [CLI reference](https://glossia.ai/docs/reference/cli/commands) for the
current command surface and limitations.

### Understand localization opportunities

The `@glossia/web` SDK provides cookieless web analytics designed to surface
localization opportunities. Audience geography and language can help prioritize
language investment without implying that translation alone guarantees growth.
See the [analytics documentation](https://glossia.ai/docs/explanation/localization-analytics).

## How Glossia compares

Many translation platforms already support Git integrations and automation.
The choice is not simply "continuous delivery versus manual translation." It is
where content authority, editorial context, and review live.

**Choose Glossia when language work should move at the speed of your software.**
Its advantages work together: public, inspectable source; repository-owned
outputs and pull-request review; your own supported model-provider tokens; and
reuse of the validation checks your repository already trusts. You keep the
product's delivery pipeline instead of making a translation workspace the
publication authority.

A dedicated translation workspace may still fit specialist editing or contributor
coordination needs, but Glossia is built for teams that want to keep their
existing software-delivery workflow.

- [Glossia vs Crowdin](https://glossia.ai/docs/explanation/glossia-vs-crowdin)
- [Glossia vs Lokalise](https://glossia.ai/docs/explanation/glossia-vs-lokalise)
- [Glossia vs Phrase](https://glossia.ai/docs/explanation/glossia-vs-phrase)
- [Glossia vs Weblate](https://glossia.ai/docs/explanation/glossia-vs-weblate)
- [Language memory and translation memory](https://glossia.ai/docs/explanation/language-memory-and-translation-memory)

These comparisons focus on workflow tradeoffs, not an exhaustive feature or
pricing checklist. They do not promise automatic migration or feature parity.

## Get started

For the hosted service, follow the
[getting-started tutorial](https://glossia.ai/docs/tutorials/getting-started).
It covers configuring a model provider, connecting a GitHub repository, choosing
target languages, and reviewing the proposed localization baseline.

For local development:

```sh
git clone https://github.com/glossia/glossia.git
cd glossia
mise install
mise run install
cd app
mix phx.server
```

Install [mise](https://mise.jdx.dev/) first. PostgreSQL must be available locally;
the development defaults use `postgres` / `postgres` on `localhost`. The install
task starts local ClickHouse and sets up the application and operations app,
including dependencies, databases, assets, and seeds. See
[app/README.md](app/README.md) for development details.

Visit `http://localhost:$GLOSSIA_SERVER_PORT` using the port exported by mise;
without that variable, the app falls back to `4050`. Database names and ports
are scoped to the current worktree. Do not put real provider keys or private
customer content in committed configuration.

A local app boot is not the same as a fully configured deployment. Repository
integration and model-backed workflows require their own credentials and
provider configuration. Read the relevant guides before exercising those paths.

## Repository map

| Directory | Purpose |
|---|---|
| [`app/`](app/) | Elixir/Phoenix application, public website, translation workflows, REST and MCP interfaces. |
| [`app/priv/docs/`](app/priv/docs/) | Documentation: tutorials, how-to guides, reference, and explanations. |
| [`cli/`](cli/) | Rust command-line interface. |
| [`sdk/web/`](sdk/web/) | JavaScript web analytics SDK. |
| [`babel/`](babel/) | Internal Phoenix operations platform. |
| [`deploy/helm/glossia/`](deploy/helm/glossia/) | Application Helm chart. |
| [`infra/`](infra/) | Kubernetes, Flux, infrastructure configuration, and Cloudflare operator. |
| [`mobile/`](mobile/) | Mobile application sources. |

The core application uses PostgreSQL for transactional data and ClickHouse for
analytics. Production images are built from this repository and deployed through
Flux; there is no downstream deployment-wrapper repository.

## Documentation for humans and agents

Published marketing and documentation content is available as HTML and Markdown.
Append `.md` to a published page URL, or request `Accept: text/markdown` at its
HTML URL. The homepage's Markdown representation is `/index.md`. Locale-prefixed
URLs preserve the requested language, with English fallback for unpublished
translations.

```sh
curl -H 'Accept: text/markdown' https://glossia.ai/docs/explanation/why-glossia
curl https://glossia.ai/docs/tutorials/getting-started.md
```

- [`/llms.txt`](https://glossia.ai/llms.txt): discovery index with Markdown links.
- [`/llms-full.txt`](https://glossia.ai/llms-full.txt): consolidated documentation.
- [`/sitemap.xml`](https://glossia.ai/sitemap.xml): canonical public HTML URLs.

These are published-content interfaces, not alternate access paths to account
or project dashboards. Crawlers should follow `robots.txt`, use conditional
requests, and back off when rate-limited.

## Contributing and security

Bug reports, focused changes, documentation improvements, and discussions are
welcome. Start with [CONTRIBUTING.md](CONTRIBUTING.md) and the repository
[AGENTS.md](AGENTS.md) conventions. External contributions require the
[contributor agreement](CLA.md), subject to the review requirements described
in the contribution guide.

Relevant checks include `cd app && mix precommit`, `cd cli && cargo test`, and
`cd sdk/web && npm test && npm run build`. Run checks for the surface you change;
the contribution guide lists the fuller validation commands.

Report vulnerabilities privately according to [SECURITY.md](SECURITY.md).

## License

Glossia's code is public and **source-available under the
[O'Saasy License](LICENSE.md)**. It permits use, modification, distribution, and
self-hosting subject to its terms, but prohibits directly competing hosted,
managed, or SaaS offerings whose primary value is Glossia's functionality.
**It is not an OSI-approved open-source license.** Third-party components retain
their own licenses. Read the license and contribution agreement before
redistributing, offering a service, or contributing.
