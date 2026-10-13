%{
  title: "Continuous localization",
  summary: "Make language changes part of the product's versioned delivery loop, not a separate export-and-import cycle.",
  category: "explanation",
  section: "translation",
  order: 2
}
---

Continuous delivery works because small changes move through a repeatable pipeline: version control, review, validation, and deployment. Localization should fit that pipeline rather than introduce an unrelated system of record.

## The disconnected loop

In a disconnected workflow, a product change triggers an export, work happens in another tool, and translated content eventually returns. Between those steps, the source may change again. Teams have to reconcile versions, decide whether translations are stale, and coordinate another release.

The problem is not that a web editor is inherently wrong. It is that an independently authoritative editing system can separate language decisions from the code and content revision they describe.

## The repository loop

Glossia's repository workflow keeps source files and localization configuration in Git. A connected repository supplies the content and target languages. Translation changes return as reviewable repository changes, so teams can apply their existing pull-request and publishing conventions.

A typical loop is:

1. A team changes the source content with the product.
2. Glossia identifies content that needs translation or refinement.
3. Language guidance and terminology provide context for the transformation.
4. Validation checks the result and failures remain actionable.
5. Reviewers inspect the changes before the publishing pipeline delivers them.

[Progressive refinement](./progressive-refinement) explains how hashing and validation fit this loop. [Translation recovery](./translation-recovery) explains what happens when generation or validation fails.

## Continuous does not mean unreviewed

A continuously deliverable change is not necessarily an automatically approved change. Legal language, product promises, and culturally sensitive material may need specialist review. Keeping that review in the delivery loop lets a team choose the appropriate gate without maintaining a separate publication authority.

Nor does continuous localization mean translating the entire repository on every commit. Unchanged content should not consume the same resources repeatedly.

## The practical boundary

Glossia supplies language context and localization mechanics. Your repository's checks and deployment process still define when a change is safe to publish. Glossia is not a substitute for application tests or an editor's responsibility for accuracy.

Other platforms also offer Git integrations and CI automation. The distinction is the intended center of gravity: Glossia is built around content ownership and review in the repository, not a requirement to move ongoing editorial authority into a hosted translation workspace.
