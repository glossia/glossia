%{
  title: "Configure a model provider",
  summary: "Add an account model and reference it safely from repositories.",
  category: "how-to",
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

The handle is stable even when you later change the provider model behind it.

## Reference the model from a repository

Set `model` in the relevant `GLOSSIA.md` frontmatter:

```yaml
---
model: translation-default
---
```

The repository stores only the handle. The provider key remains in account settings.

## Choose which model is used by default

When `GLOSSIA.md` omits `model`, Glossia uses the account's default model. If the account does not have an explicitly marked default, it uses the first configured handle in alphabetical order.

For predictable behavior across several models, reference a handle explicitly in `GLOSSIA.md`.

## Change or rotate a provider key

Open **Settings**, select **Models**, and open the model handle. Enter a new provider key and save. Leaving the key field blank keeps the current key.

Repositories that reference the handle do not need to change.
