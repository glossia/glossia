---
id: introduction
kind: section
number: "1"
title: Introducción
---

<p class="note">[Pendiente de traducción.] La versión en inglés es la autoritativa hasta que se complete la traducción.</p>

AI-based translation systems produce better results when they are given context before
they begin: the source language, the intended tone, brand terminology, and any constraints
that do not fit neatly into key and value pairs. L10N.md is the convention by which
translators record that context as files that live next to the code they describe, so the
systems that translate the strings can read it.

The convention works because it keeps the machine-readable surface tiny and pushes the
judgment into prose. Frontmatter carries structure. Markdown carries nuance. Additional
files appear only when the translation surface actually splits. The same shape holds
whether a project has one document or many.
