%{
  title: "Glossia vs Phrase",
  summary: "Choose a repository-native language workflow with public source, your own model tokens, and reusable delivery checks.",
  category: "explanation",
  markdown_only: true,
  section: "translation",
  order: 22
}
---

**Choose Glossia when you want language work to follow your product's delivery system, rather than building a parallel translation-management process around it.** Keep the content in Git, choose supported models using your own credentials, and validate the results with the checks your repository already trusts.

[Phrase](https://phrase.com/) provides a localization suite, including Phrase Strings and Phrase TMS for different software-localization and managed-translation needs. Glossia takes a focused approach: give software teams a language OS that fits their existing review and delivery loop.

## Why choose Glossia

| Your priority | Glossia's advantage |
|---|---|
| Deliver language changes with software | Repository changes drive localization, and outputs return as reviewable changes. |
| Inspect and own the processing | Public source exposes the application and deployment implementation, with modification and self-hosting allowed under the license terms. |
| Bring your own tokens | Configure your own supported model-provider credentials; select models through account handles in repository configuration. |
| Reuse validation pipelines | Run repository-native checks on translation candidates instead of treating linguistic approval as proof that a file will build. |
| Keep durable ownership | Published files, configuration, and pull-request history remain with the repository. |

## Make localization part of continuous delivery

Glossia's change detection avoids repeating translation work for unchanged inputs. Its repository workflow keeps one open translation pull request per project and publishes progress in batches, so a fast-moving source repository does not need a new translation process for every small change.

The objective is not an unreviewed race to production. It is to make language work continuously reviewable and deliverable through the pipeline your team already uses.

Phrase offers APIs, integrations, and automation too. The advantage Glossia emphasizes is architectural alignment: the repository remains the content authority and the delivery boundary, rather than only being a place to synchronize the results of another workspace.

## Keep model choice and credentials under your control

Glossia accepts your own provider API tokens for supported models. Credentials stay in account settings; repositories select stable handles. A team can rotate a token or change the model behind a handle without rewriting its repository instructions.

Different content scopes and target languages can use different configured models. Optional decision models can assess complete translations and request correction, while humans remain responsible for linguistic judgment. See [Account models](./account-models) for the current behavior and limits.

## Your repository already knows what valid content means

A translation-management system's view of a string is not necessarily the application's view of a file. A repository may have its own parser, compiler, component rules, documentation build, and placeholder checks.

Glossia can reuse those checks through `L10N.md` validation commands. It writes the candidate temporarily to its real target path for validation and accepts it only after the required checks pass. The command and its dependencies must be available in the execution environment.

This lets the team extend its existing quality boundary rather than maintain a separate definition of "valid" solely inside a translation workspace. See [L10N.md](/docs/reference/l10n-md).

## Public implementation, not a black box

Glossia's application, CLI, SDK, and deployment sources are public. The core is open source under [Apache-2.0](https://github.com/glossia/glossia/blob/main/LICENSE-APACHE), which permits modification, distribution, self-hosting, and competing hosted services. Enterprise code under `ee/` has a separate [license](https://github.com/glossia/glossia/blob/main/ee/LICENSE.md) requiring a written commercial agreement for production use.

A broader translation suite can make sense for specialist translation operations and complex coordination. If your priority is **matching software-delivery speed with your own tokens and repository checks**, Glossia is designed to keep that workflow direct.

Moving an established translation program still requires a plan for its memories, terminology, and history. This page does not promise an automatic Phrase importer or full suite parity, or assert that Phrase lacks all equivalent integrations. Consult [Phrase's documentation](https://support.phrase.com/) for the specific product's current capabilities.
