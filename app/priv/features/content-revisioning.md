%{
  title: "Content revisioning",
  summary: "Improve your existing content in place. Glossia reviews source files for clarity, accuracy, and tone using the context you provide, then produces revised versions ready for review.",
  order: 2,
  icon: "pencil",
  hero_cta_text: "Get started",
  hero_cta_url: "/interest",
  highlights: [
    %{title: "Tone and clarity", description: "Agents review your prose for readability, jargon, and consistency with your brand voice.", icon: "message-circle"},
    %{title: "Non-destructive", description: "Revised content can overwrite the original or write to a separate path. You always control the output destination.", icon: "shield-check"},
    %{title: "Feedback loop", description: "Reviewers correct the output, update context, and each cycle narrows the gap between draft and final.", icon: "refresh-cw"}
  ]
}
---

## How revisioning works

The agent reads your source files and the context graph, merging local instructions (per-file and per-directory `GLOSSIA.md` files) with remote context (your account-level voice, glossary, and style settings). With the full picture assembled, it rewrites content for clarity, accuracy, and tone, then outputs the revised version ready for review.

## Context graph

Context in Glossia is a graph that spans your account and your repository. Account-level settings like voice and glossary provide a global baseline, while `GLOSSIA.md` files placed alongside your content add local overrides. The agent resolves this graph on every run, so your instructions stay consistent across files without repeating yourself. Reviews are incremental thanks to lockfiles that track what has already been processed, so only changed or new content gets revisited.

## Progressive refinement

Each review cycle makes the output better. Corrections feed back into context files, so repeated mistakes disappear and the output converges on your team's standard over time.
