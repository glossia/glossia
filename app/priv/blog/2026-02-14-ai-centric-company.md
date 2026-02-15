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

So why would a two-person team even try?

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

## Two people, zero organizational overhead

We are deliberately keeping the team as small as possible. Right now it is just two of us. Our goal is to stay at two or three people for as long as we can.

This is not about saving money (though it helps). It is about eliminating an entire category of work that does not produce value for users.

The more humans you add, the more coordination you need. You build trust systems, permission models, approval chains. You manage conflicts, align priorities, schedule meetings. All of that is creative energy that goes into maintaining a human organization instead of building a product.

With two people, we skip all of it. We trust each other fully. We have access to everything. There is no overhead, no politics, no process for the sake of process.

The way we make this work at scale is by delegating everything else to agents.

## Discord, an AI agent, and a single command line

Here is something that might sound unusual: our primary business interface is a [Discord](https://discord.com) server.

We have an AI agent connected to it, powered by [OpenAI](https://openai.com), with access to all the tools we need to run the business. Instead of switching between web dashboards, analytics platforms, and admin panels, we talk to the agent. Text and voice are the unit of interaction.

Through the agent, either of us can:

- Query marketing and product analytics
- Inspect production servers
- Run market research
- Gather customer feedback
- Perform competitive analysis through web browsing
- Draft content, review copy, and publish

Neither of us depends on the other to do any of this. The agent has access to our APIs, databases, and monitoring tools. It can browse the web, read documentation, and synthesize information. It is a Discord server, an OpenAI instance, and an LLM key. That is the operating system of the company.

> [!TIP]
> If you are building a small team and want to reduce coordination overhead, consider making text and voice your primary interface for business operations. A shared agent in a chat channel can replace dozens of dashboards and eliminate the need for most internal tooling.

## Deliberate technology choices

We are very intentional about our stack because it directly affects how fast we can move and how cheaply we can operate.

**For the agent (CLI):** We chose [Bun](https://bun.sh) and TypeScript. The feedback loop is fast, the type system catches errors early, and Bun lets us distribute the agent as a portable executable across platforms. No runtime dependencies for the user.

**For the server:** We chose [Elixir](https://elixir-lang.org) and the [Erlang](https://www.erlang.org) runtime. Elixir's functional nature makes it a great fit for agentic workloads. The Erlang VM is battle-tested for concurrency and fault tolerance. And here is a bonus: an AI agent can introspect the running Erlang system to understand what is happening, gather insights, and even fix issues in production.

**For infrastructure:** Everything runs on a single VPS. Not just the Glossia production server, but all the peripheral services too: [PostgreSQL](https://www.postgresql.org/) for the database, [Plausible](https://plausible.io) for privacy-friendly analytics, [Grafana](https://grafana.com) for telemetry and observability. It is all deployed with [Kamal](https://kamal-deploy.org), which gives us a simple DSL to describe what goes where.

This keeps costs extremely low. We do not depend on third-party cloud services, managed databases, or platform-as-a-service providers. We have a few external dependencies, but only for things that would take us a long time to replicate and where the cost makes sense.

When the time comes to scale across servers, we will evolve the model. But we believe we can go a very long way with this setup. And going fast matters more than going big right now.

> [!IMPORTANT]
> We are very deliberate about skipping technical complexity that engineers tend to reach for early. Kubernetes, microservices, multi-region deployments. None of that is needed at this stage, and all of it would slow us down.

## What this unlocks

Running the company this way is not just an efficiency play. It changes what we can offer and how fast we can learn.

**Cheaper for users.** The localization industry has made its tools inaccessible through complex pricing, per-word fees, and enterprise sales cycles. If your translation workflow requires procurement, pricing negotiations, and a project manager, most small teams will just ship in English. By keeping our operating costs near zero, we can offer something that is genuinely accessible.

**Faster innovation.** We want to explore a lot of ideas. New interfaces for the agent, better feedback loops, new ways to bring linguists into the workflow. A traditional company would need to staff up, align teams, and schedule roadmap reviews. We just try things. The distance between an idea and a deployed experiment is measured in hours, not quarters.

## Challenging how we work, not just what we build

We are not emotionally attached to the old ways of doing things. We are actively questioning what code review means when an agent writes most of the code. How collaboration works when there are only two humans. How you fix a bug when the agent can inspect the running system.

We make mistakes. We will keep making them. But by staying open-minded about how we design and run the business, we keep discovering ideas that influence the product. The way we operate is not separate from what we build. They are the same thing.

[McKinsey recently described](https://www.mckinsey.com/capabilities/people-and-organizational-performance/our-insights/the-agentic-organization-contours-of-the-next-paradigm-for-the-ai-era) what they call "the agentic organization," a new operating model where AI agents become first-class participants in how a company runs. We do not think of it as a model. It is just how we work.

## The bet

We are betting that a two-person team with the right tools, the right mindset, and no organizational baggage can outpace companies with hundreds of employees and millions in funding. Not on every front, but on the one that matters: delivering a fundamentally better localization experience.

The industry cannot reinvent itself. We can.
