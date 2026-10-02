%{
  title: "Glossary",
  summary: "How Glossia keeps approved translations consistent across every language and every file.",
  category: "explanation",
  section: "translation",
  order: 5
}
---

A glossary is a curated set of terms your translations must render the same way every time. "Commit" in the version-control sense stays `commit` in Spanish, becomes `提交` in Simplified Chinese, and `コミット` in Japanese. One decision per language, enforced everywhere.

## Two places a glossary can live

Glossia looks in two places for glossary entries and merges them at translation time:

- **Your repository**, in the files you already use for translation settings. `L10N.md` declares the terms, and each language's `L10N/<locale>.md` declares their translations. This is the developer-authoritative glossary: changes travel through pull requests, each language's reviewers own their own file, and nested files can refine it for part of the repository.
- **Your Glossia account**, managed through the hosted dashboard. This is the linguist-authoritative glossary: reviewers and localization contributors add or refine entries without touching the code, through the dashboard, the [REST API](/docs/reference/apis), or the [MCP server](/docs/reference/mcp). It applies to every repository the account translates.

Both places are useful, and neither replaces the other.

## When to use which

Define a term in **your Glossia account** when:

- **It applies to more than one repository.** Product names, brand terms, and company vocabulary are defined once and used everywhere.
- **The people deciding it do not work in the repository.** Linguists, reviewers, and external contributors can refine the glossary even when the repository is closed source or they have no write access to it.
- **You want to fix a term without a code change.** A corrected translation applies on the next run, with no pull request against the codebase.
- **Changes need review and history.** Every edit creates a new version with a change note, contributors can propose changes as suggestions for someone to approve, and earlier versions stay available.
- **Other tools need it.** Agents and integrations can read the glossary through the REST API and the MCP server, for example to write new content that already uses the approved terms.

Define a term in **your repository** when:

- **It belongs to this codebase.** A term whose meaning is specific to one project, such as "commit" meaning the version-control action, sits next to the code that uses it.
- **It should change together with the source text.** The term and the copy that introduced it land in the same pull request and are reviewed together.
- **Only part of the repository needs it.** A nested `L10N.md` or `L10N/<locale>.md` can add or override entries for one directory, such as marketing pages.
- **It must override the account glossary.** A repository entry wins over a account entry for the same term, for the languages it translates.

## How they combine

For each file and target language, Glossia resolves the two glossaries into one effective set:

1. Start with the account glossary entries for the target language.
2. Overlay the repository entries for that language: the terms from the file's `L10N.md` chain that have a translation in its `L10N/<locale>.md` chain. When a repository entry has the same source term as a account entry, the repository entry wins.
3. If a repository term has no translation for a language, the account entry for that language still applies. The repository never blocks a language it did not translate.

The merge happens **per target language**, not per entry. A Spanish translation of "commit" in `L10N/es.md` replaces the account's Spanish entry for "commit", but does not touch the account's Japanese entry for the same term. Reviewers can see which account entries were replaced: the translation session summary shows how many were overridden, and each file's lockfile lists them under `glossary.shadowed`.

## When the glossary changes, files re-translate

When you edit a glossary entry, Glossia only re-translates the files whose *effective glossary changed*. If a file's source text contains no matches for the edited term, its translations stay untouched. If a file uses the term, its next translation pass includes the updated instruction.

The same principle applies in reverse: adding a term used only by a subset of files does not force a full re-run.

## What a glossary is not

- Not a machine-translation dictionary. Glossia's model reads the surrounding context and can render a term differently if the sentence demands it. The glossary is guidance, not substitution.
- Not the whole style guide. Voice, tone, formality, and audience live in your account's Voice configuration and in `L10N.md`. The glossary is only for individual terms and their approved translations.
- Not silent. Every applied term is recorded in the file's lockfile so a reviewer can trace exactly which glossary entries reached the model.

## Related

- Add your first terms: [Define a glossary](/docs/how-to/define-a-glossary).
- Every entry field: [Glossary reference](/docs/reference/glossary).
- The other `L10N.md` fields: [L10N.md reference](/docs/reference/l10n-md).
