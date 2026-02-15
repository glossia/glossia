%{
  title: "Localization",
  summary: "Localize your content into any language while preserving structure, code blocks, and formatting. Glossia agents handle the heavy lifting so your team can focus on review.",
  order: 1,
  icon: "languages",
  hero_cta_text: "Get started",
  hero_cta_url: "/interest",
  highlights: [
    %{title: "Structure-aware", description: "Code blocks, frontmatter, and formatting survive localization intact. No manual cleanup required.", icon: "code"},
    %{title: "Any language pair", description: "Localize between any combination of languages. Add new targets by editing a single line in your config.", icon: "globe"},
    %{title: "Incremental updates", description: "Only changed content gets relocalized. Lockfiles track what has already been processed, saving time and cost.", icon: "zap"}
  ]
}
---

## How localization works

Glossia reads the content from your repository along with lockfiles that track what has already been processed. It then merges your local context (per-file `GLOSSIA.md` instructions) with global context (voice, glossary, and account-level settings) to build a complete picture of how your content should sound in each target language. With that context assembled, an agentic workflow localizes the changed content while preserving structure, code blocks, and formatting. Once the run completes, results are sent back to your repository as a pull request ready for review.

## Context-driven quality

Every localization benefits from the context you provide. Glossary terms, style notes, and domain-specific instructions all flow into the prompt so the agent produces output that matches your product's voice.

## Review with confidence

Outputs land as pull requests or draft files, ready for your team to review. Reviewers flag issues, update context files, and the next run incorporates those corrections automatically.
