%{
  title: "Commands",
  summary: "Reference for all Glossia command-line commands and their flags.",
  category: "reference",
  subcategory: "cli",
  order: 1
}
---

## `glossia init`

Create a starter `GLOSSIA.md` configuration file in the current repository.

```bash
glossia init
```

Fails if `GLOSSIA.md` already exists.

## Translation is server-side

Translation runs on the Glossia server, not in the command-line interface. When a commit lands,
Glossia plans the work from your `GLOSSIA.md` files, translates each file with
your account's configured model, and opens a pull request with the results. You
can watch each file and the model's turns live on the translation session page.

The model is chosen per document: a `GLOSSIA.md` `model:` naming one of your
account model handles selects it; otherwise your account's default model is used.

The command-line interface intentionally does not plan, translate, validate,
inspect, or delete generated translations. It also does not read the server's
translation lockfiles.

## `glossia revisit`

Reserved for a future source-language revision pass. The Rust command-line
interface currently returns a not-implemented error for this command.

```bash
glossia revisit
```

## Global flags

| Flag | Description |
|---|---|
| `--path <PATH>` | Override the project root directory |
| `--no-color` | Disable colored output |
