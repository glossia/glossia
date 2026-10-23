%{
  title: "Language memory and translation memory",
  summary: "How voice and terminology complement reviewed translations without tying delivery to a proprietary memory.",
  category: "explanation",
  markdown_only: true,
  section: "translation",
  order: 4
}
---

A translation memory usually records previously translated source-target segments. A matching or similar source segment can reuse earlier work. This is valuable for repetitive material and for preserving reviewed translations.

Glossia's language memory addresses another need: the principles that make new writing sound like the organization, even when the sentence has never appeared before.

## Remembering output versus remembering intent

A reviewed translation answers, "How did we translate this before?" Voice guidance and a glossary answer questions such as:

- Which product terms should remain unchanged?
- Which terminology should we use consistently?
- What tone fits this audience?
- Which language decisions should an agent respect when drafting new material?

These inputs can help with localization and with content creation in the source language. They are not limited to retrieving a matching target segment.

## Complementary tools

Translation memories and language guidance solve overlapping but distinct problems. A team may benefit from both. Glossia does not promise that model-generated text can replace every reviewed segment, or that prompting guarantees linguistic correctness.

The important architectural choice is not to make a proprietary memory the only authority for the company's language. Repository-owned content, reusable context, version history, and review all contribute to a process the team can understand and maintain.

## Context still needs review

Guidance can be incomplete or contradictory. A term may have different meanings in different products. Humans remain responsible for deciding whether the result is accurate and appropriate; validation can catch structural failures but cannot prove every sentence is right.

Read [Why Glossia](./why-glossia) for the broader model and [Continuous localization](./continuous-localization) for its relationship to delivery.
