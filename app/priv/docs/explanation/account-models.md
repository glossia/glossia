%{
  title: "Account models",
  summary: "Why model providers are configured once per account and referenced by handle.",
  category: "explanation",
  order: 2
}
---

Glossia separates repository instructions from model-provider credentials. Repositories describe what should be translated, while accounts decide which [large language model](https://en.wikipedia.org/wiki/Large_language_model) performs the work.

## Why models belong to accounts

A team often translates several repositories with the same provider relationship. Account-scoped models let administrators rotate a provider key or switch the underlying model once without editing every repository.

This boundary also keeps credentials out of source control. A repository contains a readable handle such as `translation-default`, not the provider key.

## Handles provide stable intent

The `model` field in `GLOSSIA.md` refers to an account model handle:

```yaml
model: translation-default
```

The handle expresses the repository's intent. An administrator can later update which provider model that handle selects while the repository configuration stays stable.

## Default selection

Project setup needs a model before a repository has its own `GLOSSIA.md`. Glossia therefore selects the account default. If no model is explicitly marked as default, it uses the first configured handle in alphabetical order.

Once a repository has `GLOSSIA.md`, using an explicit handle makes its choice clear to reviewers. Omitting `model` keeps the repository on the account default.

## The human review boundary

Model output is proposed work, not an automatic merge. Setup and translation activity stays visible in Glossia, while repository changes are published through a pull request for the team to review. This preserves the same quality and ownership boundary teams already use for code.
