%{
  title: "Building an AI-centric company to challenge an industry that can't reinvent itself",
  summary: "Established localization companies have the capital but not the freedom to innovate. We're designing Glossia from scratch around AI and agents, not just in the product but in how we run the entire business.",
  date: ~D[2026-02-14],
  slug: "2026-02-14-ai-centric-company",
  author: "pedro"
}
---

LLMs and agents are transforming everything. Not just what software can do, but how companies are built to make that software. At [Glossia](https://glossia.ai), we see this as a once-in-a-generation opportunity to rethink how content reaches every language. But we also know that having a good product idea is not enough. You need an organization that can move fast enough to matter.

That second part is what this post is about.

## The innovator's dilemma, playing out in real time

The localization industry is large and well-funded. Companies like Smartling, Phrase, Crowdin, and Lokalise have been building tools and services for years. They have customers, revenue, established workflows, and teams that know how to sell and support their products.

So why would a small, focused team even try?

Because of something Clayton Christensen described in [The Innovator's Dilemma](https://en.wikipedia.org/wiki/The_Innovator%27s_Dilemma): established companies struggle to adopt disruptive innovation, not because they lack resources, but because their existing business models, customer expectations, and organizational structures prevent them from doing so.

These companies built their products around translation memories, per-word pricing, and human translator workflows. Their customers have built mental models and processes around those building blocks. Changing the foundation means breaking promises to existing clients, retraining teams, and rethinking revenue models. Even with the best intentions and the capital to invest, the organizational inertia is enormous.

They need innovation capacity and commitment from their workforce to embrace new ideas. But even harder than that, they need their existing customers to come along for the ride. And those customers are invested in the old model.

This is the opening we see. Not despite having fewer resources, but because of it. We have no legacy to protect, no workflows to preserve, no clients to migrate. We can design everything from scratch.

> [!NOTE]
> The innovator's dilemma is not about technology. It is about incentives. Established companies optimize for what their current customers want, which makes it nearly impossible to pursue something fundamentally different.

## AI at the center, not at the edges

Most companies adopt AI by bolting it onto existing processes. A chatbot here, a suggestion engine there. We're going the other direction: designing the entire company to be AI-centric from day one.

This means AI is not a feature of the product. It shapes how we build, sell, support, and operate. Every decision we make starts with a question: can an agent do this?

The product itself is an agent that lives in your terminal, reads your source files, generates translations, runs your CI checks, and iterates until the output passes. That's the part people see. But behind it, the same philosophy runs the business.

## A small team, delegating everything else to agents

We are deliberately keeping the team small and staying that way for as long as it makes sense.

This is not about saving money. It is about eliminating an entire category of work that does not produce value for users.

The more humans you add, the more coordination you need. You build trust systems, permission models, approval chains. You manage conflicts, align priorities, schedule meetings. All of that is creative energy that goes into maintaining a human organization instead of building a product.

The way we make this work is by delegating everything else to agents. Marketing analysis, customer feedback synthesis, competitive research, content drafting, operational monitoring: the routine work of running the business is increasingly done by agents that we shape, review, and improve.

## Deliberate technology choices

We are very intentional about our stack because it directly affects how fast we can move and how the software behaves for the teams that self-host it.

**For the agent (CLI):** We chose Rust. It compiles to single, portable binaries across platforms with no runtime dependencies for the user.

**For the server:** We chose [Elixir](https://elixir-lang.org) and the [Erlang](https://www.erlang.org) runtime. Elixir's functional nature makes it a great fit for agentic workloads. The Erlang VM is battle-tested for concurrency and fault tolerance. And here is a bonus: an AI agent can introspect the running Erlang system to understand what is happening, gather insights, and even fix issues in production.

**For distribution:** Glossia is open source under the [O'Saasy License](https://github.com/glossia/glossia/blob/main/LICENSE.md). Teams that want to run it themselves can install the Helm chart in the repository on any Kubernetes cluster. The same code powers the hosted service at glossia.ai and any self-hosted deployment.

> [!IMPORTANT]
> We are deliberate about skipping technical complexity that engineers tend to reach for early when it isn't earned. Every dependency and every layer of infrastructure has to justify its weight.

## What this unlocks

Running the company this way is not just an efficiency play. It changes what we can offer and how fast we can learn.

**Accessible to more teams.** The localization industry has made its tools inaccessible through complex pricing, per-word fees, and enterprise sales cycles. If your translation workflow requires procurement, pricing negotiations, and a project manager, most small teams will just ship in English. By building an efficient organization and shipping the software open source so teams can self-host, we can make Glossia genuinely accessible.

**Faster innovation.** We want to explore a lot of ideas. New interfaces for the agent, better feedback loops, new ways to bring linguists into the workflow. A traditional company would need to staff up, align teams, and schedule roadmap reviews. We just try things. The distance between an idea and a deployed experiment is measured in hours, not quarters.

## Challenging how we work, not just what we build

We are not emotionally attached to the old ways of doing things. We are actively questioning what code review means when an agent writes most of the code. How collaboration works when the human team is small and agents do the routine work. How you fix a bug when the agent can inspect the running system.

We make mistakes. We will keep making them. But by staying open-minded about how we design and run the business, we keep discovering ideas that influence the product. The way we operate is not separate from what we build. They are the same thing.

[McKinsey recently described](https://www.mckinsey.com/capabilities/people-and-organizational-performance/our-insights/the-agentic-organization-contours-of-the-next-paradigm-for-the-ai-era) what they call "the agentic organization," a new operating model where AI agents become first-class participants in how a company runs. We do not think of it as a model. It is just how we work.

## The bet

We are betting that a small team with the right tools, the right mindset, and no organizational baggage can outpace companies with hundreds of employees and millions in funding. Not on every front, but on the one that matters: delivering a fundamentally better localization experience.

The industry cannot reinvent itself. We can.
