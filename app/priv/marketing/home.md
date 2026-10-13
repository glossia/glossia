# Glossia: a language OS for teams

Glossia brings voice, terminology, translation, revision history, and localization analytics into one system. It helps developers, linguists, and product teams communicate consistently across languages without moving their content out of Git.

## The problem

Shipping in another language is not just replacing words. Teams need to preserve meaning, use the right terminology, adapt tone to the audience, and keep translations current as the product changes. Context scattered across spreadsheets, prompts, and translation tools leads to inconsistent writing and repeated manual work.

An LLM can draft a translation, but a draft alone does not provide version history, validation, selective updates, or a feedback loop for the next change.

## Glossia's role

- **Language memory:** shared voice guidance and glossary entries help people and agents use consistent language.
- **Repository localization:** connect a repository, describe source files and target locales in configuration, and review changes through pull requests.
- **Progressive refinement:** content hashes help avoid translating unchanged content. Validation and recovery make failures visible and actionable.
- **Content revisioning:** preserve the history of language decisions and changes instead of treating each generation as an isolated prompt.
- **Localization analytics:** privacy-conscious web analytics help teams understand their audience and where localization is worth investing in.
- **Agent integration:** an OAuth-authenticated MCP server and REST interfaces make language context available to existing workflows.

Glossia does not replace editorial judgment. It supplies the context, automation, and review workflow that let teams apply that judgment repeatedly.

## Explore

- [Getting started](/docs/tutorials/getting-started.md): connect a repository and run your first localization workflow.
- [Why Glossia](/docs/explanation/why-glossia.md): the problems the language OS is designed to solve.
- [Features](/features.md): product capabilities and use cases.
- [Documentation](/docs.md): tutorials, how-to guides, reference, and explanations.
- [Blog](/blog.md): writing about localization and language systems.
- [Changelog](/changelog.md): product changes.
- [Source code](https://github.com/glossia/glossia): inspect the implementation and contribute.

## Comparisons

- [Glossia vs Crowdin](/docs/explanation/glossia-vs-crowdin.md)
- [Glossia vs Lokalise](/docs/explanation/glossia-vs-lokalise.md)
- [Glossia vs Phrase](/docs/explanation/glossia-vs-phrase.md)
- [Glossia vs Weblate](/docs/explanation/glossia-vs-weblate.md)

## For crawlers and agents

Published pages are available as Markdown by appending `.md` to their URL, or by requesting `Accept: text/markdown` at the HTML URL. The homepage's Markdown URL is `/index.md`. Translated content uses the same locale prefixes as HTML and falls back to English when no translation is published.

Use [/llms.txt](/llms.txt) for discovery, [/llms-full.txt](/llms-full.txt) for a consolidated documentation export, and [/sitemap.xml](/sitemap.xml) for canonical HTML URLs. Account dashboards are application surfaces, not documentation; do not crawl them to learn about Glossia.
