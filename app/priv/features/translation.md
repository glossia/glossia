%{
  title: "Translation",
  summary: "Translate your content into any language while preserving structure, code blocks, and formatting. Glossia agents handle the heavy lifting so your team can focus on review.",
  order: 1,
  icon: "languages",
  hero_cta_text: "Get started",
  hero_cta_url: "/interest",
  highlights: [
    %{title: "Structure-aware", description: "Code blocks, frontmatter, and formatting survive translation intact. No manual cleanup required.", icon: "code"},
    %{title: "Any language pair", description: "Translate between any combination of languages. Add new targets by editing a single line in your config.", icon: "globe"},
    %{title: "Incremental updates", description: "Only changed content gets retranslated. Lockfiles track what has already been processed, saving time and cost.", icon: "zap"}
  ]
}
---

## How translation works

Point Glossia at your source files, list the target languages, and run `glossia translate`. The agent reads your content alongside any context you provide in `GLOSSIA.md` files, then produces localized versions that preserve the original structure.

## Context-driven quality

Every translation benefits from the context you provide. Glossary terms, style notes, and domain-specific instructions all flow into the prompt so the agent produces output that matches your product's voice.

## Review with confidence

Outputs land as pull requests or draft files, ready for your team to review. Reviewers flag issues, update context files, and the next run incorporates those corrections automatically.
