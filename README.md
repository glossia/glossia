# Glossia

Glossia is the language operating system for your organization. It brings your
voice, terminology, and tone together so linguists and product teams can shape
how your organization communicates across every language and surface.

## Get started

Visit [glossia.ai](https://glossia.ai) to learn more and read the
[documentation](https://glossia.ai/docs).

To run the web application locally:

```bash
cd app
mise run install
mix phx.server
```

To start translating from the command line, install Glossia with
[mise](https://mise.jdx.dev/) and run:

```bash
mise exec -- glossia init
mise exec -- glossia translate
```
