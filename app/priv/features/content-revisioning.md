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

Run `glossia revisit` and the agent reads your source files alongside the instructions in your `GLOSSIA.md` context files. It rewrites content for clarity, accuracy, and tone, then outputs the revised version.

## Context as instructions

Your `GLOSSIA.md` files act as the brief. Describe the audience, the tone, specific terms to use or avoid, and the agent follows those instructions on every run.

## Progressive refinement

Each review cycle makes the output better. Corrections feed back into context files, so repeated mistakes disappear and the output converges on your team's standard over time.
