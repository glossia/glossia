%{
  title: "Add a new language",
  summary: "How to add a target language to an existing Glossia setup.",
  category: "how-to",
  order: 1
}
---

If you already have Glossia configured and want to add another target language, follow these steps.

## 1. Update CONTENT.md

Open your `CONTENT.md` and add the new language code to the `targets` array:

```toml
[[content]]
source = "docs/**/*.md"
targets = ["es", "fr", "de", "ja"]  # added "ja"
output = "docs/i18n/{lang}/{relpath}"
```

## 2. Add language-specific context (optional)

If the new language needs special instructions (e.g., formality level, character set considerations), create a context override file:

```
CONTENT/
  ja.md
```

Write any language-specific guidance in that file. Glossia merges it with the base context for Japanese translations.

## 3. Run the translation

```bash
glossia translate
```

Glossia detects the new language and generates translations for all source files. Existing translations for other languages are skipped because their hashes have not changed.

## 4. Review the output

```bash
glossia status
```

Check that the new language files appear at the expected output paths.
