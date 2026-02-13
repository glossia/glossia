%{
  title: "Progressive refinement",
  summary: "Why content quality converges over time, not in a single pass.",
  category: "explanation",
  order: 1
}
---

First drafts from LLMs are structurally correct but may miss nuance, tone, or domain-specific phrasing. That is by design. Glossia treats content generation the same way software teams treat code: ship a working version, review it, and improve iteratively.

## The refinement loop

1. **Draft**: Glossia generates a structurally valid first pass based on your source files and the context in `CONTENT.md`.
2. **Review**: Your team flags issues through pull requests and diffs, the same workflow you already use for code.
3. **Refine**: Updated context files, glossary corrections, and review feedback feed into the next run.
4. **Converge**: Each cycle narrows the distance to production quality. The system learns your product's voice through the context you provide.

## Why this works

The key insight is that context accumulates. Every review comment that leads to an updated `CONTENT.md` or a corrected glossary entry improves all future runs, not just the file that triggered the review.

This follows the same principle behind Kaizen in manufacturing and successive approximation in engineering: start with a good-enough baseline and systematically improve it with human judgment in the loop.

## Practical implications

- Do not expect perfection on the first run. Plan for one or two review cycles.
- Invest time in writing clear context files. They are the highest-leverage improvement you can make.
- Use `glossia status` to track which files have been updated since their last generation.
