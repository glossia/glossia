%{
  title: "Account models",
  summary: "Why model providers are configured once per account and referenced by handle.",
  category: "explanation",
  section: "platform",
  order: 2
}
---

Glossia separates repository instructions from model-provider credentials. Repositories describe what should be translated, while accounts decide which [large language model](https://en.wikipedia.org/wiki/Large_language_model) performs the work.

## Why models belong to accounts

A team often translates several repositories with the same provider relationship. Account-scoped models let administrators rotate a provider key or switch the underlying model once without editing every repository.

This boundary also keeps credentials out of source control. A repository contains a readable handle such as `translation-default`, not the provider key.

## Handles provide stable intent

The `model` field in `L10N.md` refers to an account model handle:

```yaml
model: translation-default
```

The handle expresses the repository's intent. An administrator can later update which provider model that handle selects while the repository configuration stays stable.

## How several models are used

Glossia uses one configured **generative** model for each document translation. Adding several models does not create an ensemble, a fallback chain, or an automatic quality tier. The repository author chooses their purpose through stable handles such as `translation-default`, `long-form`, or `japanese-specialist`.

Selection follows the context hierarchy for the document and target locale:

1. The closest `L10N/<locale>.md` file that declares `model` wins for that locale.
2. Otherwise, the closest `L10N.md` file that declares `model` wins for its directory.
3. Parent `L10N.md` settings are inherited when a closer file does not declare a model.
4. When no applicable context file declares a handle, Glossia uses the account default generative model.

An explicitly configured handle must exist. Glossia reports an error for an unknown handle instead of silently switching to the account default.

## Default selection

Project setup needs a model before a repository has its own `L10N.md`. Glossia therefore selects the account default. The first model added to each category becomes that category's default, and an administrator can make another model the default from its settings page.

Once a repository has `L10N.md`, using an explicit handle makes its choice clear to reviewers. Omitting `model` keeps the repository on the account default.

## Generative and decision models

Model configurations have two categories:

- **Generative** models write translations and power project setup. Repository model handles and locale routing rules select only this category.
- **Decision** models assess translations against a fixed quality rubric. When an account has a decision model, its default decision model automatically checks each translated repository document after structural validation and complete, single-document translations from the content endpoint. Fragment requests are generation primitives; repository runs assess their assembled output.

The categories have independent defaults. Adding Jev never changes the model that writes your translations. The first decision model enables evaluation for subsequent translation runs; deleting the last one disables evaluation. Accounts without decision models keep their existing behavior.

Glossia currently supports [TypeSafe Jev](https://docs.typesafe.ai/introduction) as a decision provider. Jev returns predefined choices and scores rather than prose. Glossia converts weakness choices into correction hints, without presenting them as located or independently verified errors.

## Quality checks and revisions

The evaluator receives the source, translation, target locale, content format, project instructions, and resolved organization context. It assesses meaning preservation, completeness, terminology, fluency, document coherence, purpose and audience fit, and locale appropriateness. Voice and register are assessed when voice, project, or document guidance is available.

Each dimension must reach the configured minimum score, which defaults to 7 out of 10. A major or critical error always requests correction, regardless of score. Confidence is included in live assessment events and does not change acceptance. These events are currently not retained or displayed in the dashboard. A threshold of 10 requires a perfect weighted score and is usually too strict.

Failed dimensions feed their predefined correction hints into the next translation attempt. The repository's existing `retries` setting bounds these revisions; the content endpoint allows three correction retries, configurable from zero to three with its `retries` field. The complete revised document passes structural checks and quality evaluation again before it is accepted.

Transient provider failures retry with exponential backoff up to three times; invalid credentials and malformed responses fail immediately. Exhausted provider failures stop the file's translation; unchecked output is never accepted. Evaluations use complete documents, and oversized evaluation input is rejected rather than truncated. Serialized input is conservatively limited to 30,000 bytes for state plus the longest question, and 60,000 bytes across the full request, to stay within [Jev’s context limits](https://docs.typesafe.ai/models). Automated scores are model judgments and still require calibration against bilingual human review.

The evaluator configuration and rubric version participate in translation lockfiles. Enabling evaluation, changing models or thresholds, or removing evaluation makes prior translations stale for the next run. Provider keys are excluded from lockfiles.

## The human review boundary

Model output is proposed work, not an automatic merge. Setup and translation activity stays visible in Glossia, while repository changes are published through a pull request for the team to review. This preserves the same quality and ownership boundary teams already use for code.
