%{
  title: "Add a new language",
  summary: "How to add a target language to an existing Glossia setup.",
  category: "how-to",
  order: 1
}
---

If you already have Glossia configured and want to add another target language, follow these steps.

## 1. Update GLOSSIA.md

Open your `GLOSSIA.md` and add the new language code to the `targets` array:

```yaml
targets:
  - es
  - fr
  - de
  - ja
```

## 2. Add language-specific context (optional)

If the new language needs special instructions, such as formality level or character set considerations, create a context override file:

```
GLOSSIA/
  ja.md
```

Write any language-specific guidance in that file. Glossia merges it with the base context for Japanese translations.

## 3. Publish the configuration change

Commit and push the updated configuration. If the repository is connected to
Glossia, the server detects the new target language and starts a translation
session.

Existing translations for other languages remain unchanged when their inputs
and effective context have not changed.

## 4. Review the translation pull request

Follow the translation session in Glossia, then review the generated language
files in the pull request opened by the server.
