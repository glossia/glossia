%{
  title: "Configure a model provider",
  summary: "Add an account model and reference it safely from repositories.",
  category: "how-to",
  section: "translation",
  order: 3
}
---

Project setup and translation runs use models configured for the current Glossia account. Configure at least one model before creating a project.

## Add a model

1. Open **Settings** and select **Models**.
2. Select **New model**.
3. Enter a unique handle, such as `translation-default`.
4. Open the model picker and type part of a provider or model name to filter the list.
5. Select a model and enter its provider key.
6. Save the model.

The handle is stable even when you later change the provider model behind it. The first model added to an account becomes its default.

## Reference the model from a repository

Set `model` in the relevant `L10N.md` frontmatter:

```yaml
---
model: translation-default
---
```

The repository stores only the handle. The provider key remains in account settings.

## Choose which model is used by default

When `L10N.md` omits `model`, Glossia uses the account's default model. To change it, open the model that should become the default and select **Make default**.

For predictable behavior across several models, reference a handle explicitly in `L10N.md`.

You can place a different `model` handle in a nested `L10N.md` for one content area, or in `L10N/<locale>.md` for one target locale. Glossia uses the closest applicable setting for each document and locale. It does not automatically split work among configured models.

If an explicit handle does not exist in the account, the translation stops with an error. It does not fall back to another model.

## Change or rotate a provider key

Open **Settings**, select **Models**, and open the model handle. Enter a new provider key and save. Leaving the key field blank keeps the current key.

Repositories that reference the handle do not need to change.

## Add Jev for translation quality decisions

1. Open **Settings → Models → New model** and select **Decision** as the category.
2. Use a handle such as `translation-quality`. Keep `typesafe/jev-latest`, or enter a pinned TypeSafe Jev model version.
3. Enter your TypeSafe provider key. Leave the base address empty to use the native TypeSafe endpoint; a custom address must include its version prefix, such as `https://api.typesafe.ai/v1`.
4. Set the minimum quality score from 1 to 10, then save. The first decision model becomes the default decision model and enables evaluation automatically.
5. Run translation. Failed quality dimensions request correction within the `retries` budget configured in your repository.

Generative and decision models have separate defaults. Keep your translation model handles unchanged. Decision models cannot be selected by repository translation handles or locale routing rules. Remove all decision models to disable evaluation.
