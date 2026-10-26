%{
  title: "Why Glossia",
  summary: "A language OS that keeps content, context, and review aligned with continuous delivery.",
  category: "explanation",
  section: "translation",
  order: 1
}
---

A product can ship continuously while its translations remain stuck in a separate release cycle. Source content changes in Git, someone exports it to a translation system, editors work there, and someone imports the result. The product and its language versions drift apart.

Glossia is a language OS built around a different premise: language work should follow the same versioned, reviewable delivery loop as the product itself.

## The problem is larger than translation

Teams need to preserve meaning, apply terminology, match the audience's tone, and update content as the product evolves. Those decisions affect documentation, UI strings, marketing pages, and agent-generated writing alike.

A model can produce a useful draft. It does not, by itself, know your organization's language decisions, record why a phrase changed, validate your file formats, or synchronize the next source revision. Repeating a prompt is not a delivery system.

Glossia combines language context with the mechanics around generation: configuration, change detection, validation, failure recovery, revision history, and review.

## Content stays with the product

The repository remains the authority for published content. Source files, configuration, generated translations, and reviewable changes can travel through Git and pull requests. Teams do not need to make a hosted editing interface the authority for every sentence before they can deliver a localized release.

This makes language changes visible alongside the product change that motivated them. A reviewer can inspect the diff, CI can validate the output, and the same delivery pipeline can publish it.

Read [Continuous localization](./continuous-localization) for the delivery model and [Content ownership](./content-ownership) for its portability implications.

## Context is an input, not a cage

Voice guidance and terminology help both humans and agents write consistently. They are reusable language decisions, not just a proprietary collection of source-target segment pairs.

Translation memories remain useful for established translations and repetitive content. The point is not to discard them. The point is to avoid making one vendor's memory format or editing workflow the only place where a company's language knowledge can live.

## Improvement is a loop

Glossia's progressive-refinement model uses content hashes to avoid redundant work, runs validation around transformations, and exposes failures so a run can recover. Human corrections can inform the next iteration rather than disappearing into an isolated generation.

Localization analytics provides another input: understanding the languages and places an audience uses can help a team decide where to invest. It is evidence for prioritization, not a promise that a translation will produce growth.

## Who this fits

Glossia is especially relevant when developers, linguists, and product teams want to collaborate on repository-managed content and release it continuously. It is not a claim that every organization should abandon its existing TMS. A team whose central requirement is a mature browser-based editor, translation-agency coordination, or a large established memory may prefer another workflow.

## Inspectable implementation

Glossia's code is publicly available, including its Phoenix application, Rust CLI, web SDK, and deployment infrastructure. That makes the mechanics of language work inspectable rather than a black box.

Glossia follows an open-core model. The core uses [Apache-2.0](https://github.com/glossia/glossia/blob/main/LICENSE-APACHE), which permits commercial use, self-hosting, and competing hosted services. The `ee/` directory has a separate [Enterprise License](https://github.com/glossia/glossia/blob/main/ee/LICENSE.md) requiring a written commercial agreement for production use. Read the applicable license before redistributing or operating enterprise features.
