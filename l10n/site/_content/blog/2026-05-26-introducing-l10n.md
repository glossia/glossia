---
title: "Introducing L10N.md"
date: "2026-05-26"
description: "A lightweight convention for giving AI translation systems the context they need."
author: "Glossia"
---

Machine translation has come a long way, but the difference between a good
translation and a great one often comes down to context. Should "workspace" be
translated as "espacio de trabajo" or kept in English? Is the tone formal or
friendly? Are em dashes allowed?

L10N.md is a simple convention that answers these questions before translation
starts. It works like this: you add an `L10N.md` file to your repository with
YAML frontmatter for machine-readable settings (source language, target locales,
validation commands) and Markdown prose for everything machines can't guess
(brand voice, terminology rules, formatting constraints).

### How it works

A root `L10N.md` carries repository-wide guidance. Scoped `L10N.md` files
nested in directories override settings for specific subtrees. And locale
overlays in `L10N/<locale>.md` provide per-language nuance.

Each document validates against a JSON Schema. Translation tools read
these documents and pass the context to LLMs before generating translations.

### What's next

We're using L10N.md to dogfood the convention -- this specification site is
translated into Spanish and Japanese through the same workflow we're
describing. The standard is versioned, so improvements ship without
breaking existing files.

[Read the specification](/v1/) to get started.
