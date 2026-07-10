%{
  title: "Getting started",
  summary: "Set up Glossia in your project and run your first translation.",
  category: "tutorials",
  order: 1
}
---

This tutorial walks you through installing Glossia, creating a configuration file, and running your first content translation.

## Prerequisites

- A project with content files (Markdown,
  [JavaScript Object Notation (JSON)](https://www.json.org/json-en.html),
  [YAML Ain't Markup Language (YAML)](https://yaml.org/), or
  [Portable Object (PO)](https://www.gnu.org/software/gettext/manual/html_node/PO-Files.html))
- An [application programming interface](https://developer.mozilla.org/en-US/docs/Glossary/API)
  key for at least one
  [large language model](https://en.wikipedia.org/wiki/Large_language_model)
  provider (OpenAI, Anthropic, or Vertex AI)

## Install Glossia

Add Glossia to `mise.toml`:

```toml
[tools."http:glossia"]
version = "latest"
url = 'https://releases.glossia.ai/cli/{{ version }}/glossia-{{ os(macos="darwin") }}-{{ arch() }}.{{ os(windows="zip", macos="tar.gz", linux="tar.gz") }}'
version_list_url = "https://releases.glossia.ai/cli/versions.txt"
checksum_url = 'https://releases.glossia.ai/cli/{{ version }}/SHA256SUMS'
```

Then install it:

```bash
mise install
```

## Initialize your project

Run the init command to set up a `GLOSSIA.md` configuration file:

```bash
mise exec -- glossia init
```

This writes a starter `GLOSSIA.md` at the project root and creates `glossia.toml` for local provider settings when it does not already exist.

## Run your first translation

Once `GLOSSIA.md` is in place, translate your content:

```bash
mise exec -- glossia translate
```

Glossia reads your source files, sends them to the configured model, validates the output, and writes the translated files to the paths defined in your configuration.

## Check the results

Review what Glossia produced:

```bash
mise exec -- glossia status
```

This shows which files are up to date, which are stale, and which are missing.
