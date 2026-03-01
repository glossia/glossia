%{
  title: "The missing operating system for language",
  summary: "Software has frameworks, design systems, and Git. Language has... nothing. We think it's time to build the OS where linguists take the lead and organizations finally treat content with the same care they treat code.",
  date: ~D[2026-02-16],
  slug: "2026-02-16-the-missing-os-for-language",
  author: "pedro"
}
---

Think about how far software has come in giving teams shared tools to work consistently. [Frameworks](https://en.wikipedia.org/wiki/Software_framework) let developers express logic in predictable patterns. [Design systems](https://en.wikipedia.org/wiki/Design_system) let designers and engineers share a visual language across every screen and surface. [Git](https://en.wikipedia.org/wiki/Git) gave us a foundation for collaboration, versioning, and review that [GitHub](https://github.com) and [GitLab](https://gitlab.com) turned into something millions of people use every day.

> [!NOTE]
> If you are not a developer: [Git](https://en.wikipedia.org/wiki/Git) is a [version control](https://en.wikipedia.org/wiki/Version_control) system, a tool that tracks every change made to a set of files so teams can collaborate without overwriting each other's work. Think of it like "Track Changes" in a word processor, but for entire projects. [GitHub](https://github.com) and [GitLab](https://gitlab.com) are platforms built on top of Git that make it easy for people to propose changes, review each other's work, and discuss improvements before accepting them.

Now think about language. The actual words your product speaks to people. The tone of your error messages. The way your marketing copy sounds in Japanese versus the way it sounds in German. The terminology your support team uses compared to what your product UI says.

There is no shared system for any of that. No framework. No design system. No Git. Nothing.

## We never built the infrastructure

It is not that the theories don't exist. Linguistics is a rich field. [Eugene Nida](https://en.wikipedia.org/wiki/Eugene_Nida)'s concept of [dynamic equivalence](https://en.wikipedia.org/wiki/Dynamic_equivalence) taught us that good translation is not about swapping words but about recreating the same felt relationship between the reader and the message. Discourse analysis, pragmatics, sociolinguistics, all of these disciplines have spent decades understanding how language works in context. The intellectual foundation is there.

But nobody built a system around it.

When the internet arrived, localization companies took their proprietary desktop applications and moved them to the browser. The underlying model stayed the same: [translation memories](https://en.wikipedia.org/wiki/Translation_memory), [fuzzy matching](https://en.wikipedia.org/wiki/Fuzzy_matching_(computer-assisted_translation)), per-word pricing. They kept building on the same foundation, and when machine translation improved, they bolted it on top. No rethinking, no reimagining. Just the same workflow with a faster engine underneath.

And then came the intermediaries.

Between you (the person or company that has content) and the linguist (the person who actually understands language), an entire industry of middlemen emerged. Integration platforms. Translation management systems. Translation agencies. Quality assurance layers. Project management dashboards. Each one adding complexity, each one taking a cut. The person who contributes the most value, the linguist who brings cultural awareness, terminological precision, and creative judgment, ends up at the very end of the chain, earning the least.

[Reports from the industry](https://traductoresnativos.com/en/translation-agencies-2025-summary-2026/) show that AI post-editing rates can drop to 50-70% of already modest per-word fees, while agencies request discounts of 30-40% on top of that. The supply chain squeezes the people it depends on most.

## A sign that something is missing

Here is something that tells you the current tools are not enough: companies are creating a role called ["Language Manager"](https://slator.com/10-language-jobs-big-tech-is-hiring-for-right-now/). These are people whose entire job is to maintain glossaries, oversee translation workflows, enforce terminology consistency, and coordinate between linguists, product teams, and marketing departments.

The fact that this role exists is a signal. It means organizations need linguistic consistency across all their surfaces and the tools they have don't provide it. So they hire a human to be the glue.

And these people end up stuck in an uncomfortable dichotomy. On one hand, they can ask for engineering resources to build an internal system, but that requires a huge investment in something that is not their employer's core business. On the other hand, they can look for an external tool, but nobody has really built a comprehensive solution for this. What exists are smaller, disconnected pieces that they have to orchestrate and glue together themselves. Neither option is satisfying.

That is exactly the gap a system should fill. Not by replacing the Language Manager, but by giving them (and every linguist they work with) a proper operating system to do their work in.

## What we are building with Glossia

We think the answer looks less like a translation tool and more like what GitHub did for code.

GitHub took Git, a system for tracking changes to files, and turned it into a collaborative platform where developers review each other's work, discuss changes, and iterate together. Before GitHub, contributing to software projects required emailing files back and forth. After GitHub, anyone with an account could participate.

We want to do the same thing for language.

Glossia is the OS where organizations capture their linguistic preferences, their voice, their terminology, their tone, their audience expectations, and where linguists are at the center of iterating on those preferences. Not at the end of a chain. Not behind three layers of intermediaries. At the center.

We talked about this in our post on [the context graph](https://glossia.ai/blog/2026-02-15-context-graph): we are building a structured map of connected knowledge that captures everything an organization knows about its language over time. Voice definitions, glossary entries, audience profiles, formality rules. Each piece is versioned (so you can see what changed and when) and connected to everything it relates to. When something changes, the system knows exactly what content is affected and what needs to be revisited.

This is your account on Glossia, and the many projects you can contribute to. A linguist can work across multiple organizations, bring their expertise to different contexts, and see the impact of their decisions propagate through the system. Like a developer who contributes to multiple projects on GitHub, a linguist on Glossia can shape how dozens of products speak.

## AI as an amplifier, not a replacement

The dominant narrative around AI and language is about replacement. Faster, cheaper, fewer humans. We think that is profoundly wrong, and frankly, it is disrespectful to the depth of expertise that linguists bring.

Our take is different. AI is a tool that runs on a system shaped by linguistic input. It does not replace the linguist. It amplifies what linguists make possible.

When a linguist refines a voice definition on Glossia, that refinement flows into every piece of content the system touches. When a terminologist updates a glossary entry, that update is reflected the next time any agent generates or transforms content for that organization. The human decision gets multiplied across hundreds or thousands of outputs. That is leverage that was never available before.

Translation is the most obvious use case, and it is where we started. But it is not the only one. Once an organization has built up a rich context graph, full of the linguistic memory that their team of linguists has developed over months and years, the possibilities expand:

- A marketing team can connect their writing tools to this OS via [MCP](https://modelcontextprotocol.io/) (Model Context Protocol, a standard that lets AI tools talk to external systems) and ensure that every campaign adheres to the company's terminology and voice.
- A product team can validate that their UI copy matches the tone defined for their audience.
- A support team can generate responses that sound like the brand, not like a generic chatbot.

The linguistic knowledge becomes a shared resource, like a design system but for language.

## Linguists deserve better tools

If you are a linguist or a translator reading this, I want you to know that this project exists because of you, not in spite of you.

The localization industry has spent years pushing you further from the people and organizations you serve. It has commoditized your work, compressed your rates, and treated your expertise as an afterthought in a pipeline optimized for throughput.

We think linguists should be first-class participants in how organizations communicate. You understand register, pragmatics, cultural context, and the subtle differences between what a sentence says and what it means. No model can replace that. But a system can make it so that your insights reach further, last longer, and shape more than any single translation ever could.

We are building Glossia so that your expertise becomes the foundation that everything else runs on. Not a step at the end of a chain. The foundation.

## What comes next

We are still early. The [CLI agent](https://glossia.ai/docs) (a command-line tool, meaning you interact with it by typing commands in a terminal rather than clicking buttons in a visual interface) is where we started because that is where the hardest infrastructure problems live: reading source files, generating outputs, validating with your own tools, and closing the feedback loop. But as we described in our [first post](https://glossia.ai/blog/2026-02-03-why-l10n), the terminal is the first interface, not the only one.

We are designing experiences where linguists can see content and context side by side, refine voice definitions through collaborative sessions, and watch their decisions flow through the system in real time. We want the experience of contributing linguistic expertise to feel as natural and rewarding as contributing code on GitHub.

If any of this resonates with you, whether you are a linguist who has felt sidelined by the tools you are asked to use, a Language Manager looking for the system you wish existed, or just someone who believes that how we speak matters as much as how we build, we would love to hear from you. Join our [Discord](https://discord.gg/7FRHkwvs) or keep an eye on the [blog](https://glossia.ai/blog). The conversation is just getting started.
