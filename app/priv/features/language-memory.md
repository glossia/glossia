%{
  title: "Language memory",
  summary: "A versioned context layer that captures your organization's voice, terminology, and style. Language memory guides every agent workflow and extends to your own tools through the API and MCP.",
  order: 5,
  icon: "brain",
  hero_cta_text: "Get started",
  hero_cta_url: "/interest",
  highlights: [
    %{title: "Versioned and auditable", description: "Every change to your voice or glossary creates a new immutable version. You can review the history, compare iterations, and roll back if something drifts.", icon: "git-branch"},
    %{title: "Beyond localization", description: "Language memory is not just for localization. Use it to generate marketing copy, draft documentation, review pull requests, or craft social posts, all in your organization's voice.", icon: "megaphone"},
    %{title: "Open and extensible", description: "Access language memory through the REST API or MCP server. Feed it into your own CI pipelines, content tools, or custom agents to maintain consistency everywhere you write.", icon: "puzzle"}
  ]
}
---

## What is language memory?

Language memory is the accumulated context that tells Glossia's agents how your organization communicates. It is made up of two core primitives that you create and refine over time:

**Voice** defines how content should sound. Tone, formality, target audience, and freeform guidelines all live here. You can set a base voice for your account and then override specific fields for individual locales, so your Japanese copy can be more formal while your English stays conversational.

**Glossary** defines what terms mean and how they should be localized. Each entry carries a definition and per-locale translations. When an agent encounters "workspace" in your source content, the glossary tells it whether to localize, transliterate, or leave it untouched, and exactly which word to use in each target language.

Together, voice and glossary form a context layer that agents consult on every run. The more you invest in this layer, the less review your output needs.

## Immutable versioning

Language memory is append-only. When you update your voice or glossary, Glossia creates a new version rather than overwriting the old one. Every version records who created it, when, and an optional change note explaining what evolved.

This means you always have a full audit trail. You can compare version 3 against version 7 to understand how your tone shifted over a quarter. If a recent change introduced inconsistencies, roll back to a previous version and keep going.

Versioning also makes collaboration safer. Multiple team members can propose voice changes without worrying about conflicts, because each change is a discrete, traceable event.

## Locale-aware resolution

When an agent runs a workflow for a specific locale, Glossia resolves the language memory for that context. It starts with your base voice settings and then applies any locale-specific overrides on top. The same happens with glossaries: only entries that have a localized term for the target locale are included.

This resolution step means agents always work with the most relevant context. You do not need to maintain separate configurations per language. Define your defaults once, override where it matters, and let the resolution system handle the rest.

## Use it everywhere

Language memory was designed for localization, but it is useful anywhere you produce text. Because the context is accessible through the [REST API](/features/rest-api) and the [MCP server](/features/mcp-server), you can integrate it into workflows beyond localization:

**Marketing and social content** -- Pull your organization's voice into a content agent that drafts social media posts, email campaigns, or landing page copy. The glossary keeps brand terms consistent and the voice settings ensure the tone matches your brand.

**Documentation** -- Feed language memory into a documentation pipeline so technical writing follows the same style rules as the rest of your content. Glossary entries prevent terminology drift across docs, help articles, and in-product copy.

**Code review** -- Build an agent that reviews pull request copy (error messages, UI labels, onboarding text) against your voice and glossary. Flag inconsistencies before they ship.

**Custom agents** -- Any MCP-compatible client can read and write language memory. Ask your coding assistant to "update the glossary with the new product name" or "set the voice tone to professional for the German locale" and it translates your intent into the right API call.

## Progressive refinement

Language memory improves with use. Each time a reviewer corrects an agent's output, that correction feeds back into the next version of your voice or glossary. Over time, the gap between first draft and final output narrows, and the review step becomes faster.

This is the feedback loop at the heart of Glossia: generate, review, refine context, generate again. The agents do not just follow instructions. They work with context that gets better every cycle.
