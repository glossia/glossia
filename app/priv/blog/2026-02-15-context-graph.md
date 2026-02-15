%{
  title: "The context graph: codifying decades of linguistic theory for the agentic era",
  summary: "Language models are powerful but they need the right context to produce great content. We are designing a versioned, directed graph to capture linguistic knowledge and share it with agents, and we think this is what will make Glossia stand out.",
  date: ~D[2026-02-15],
  slug: "2026-02-15-context-graph",
  author: "pedro"
}
---

I've been thinking a lot about what makes the difference between content that sounds machine-generated and content that feels like it was written by someone who understands the audience, the brand, and the cultural nuances behind every word. The answer keeps coming back to the same thing: **context**.

Language models are getting better at languages, and we're betting on that trajectory continuing. They're not fully there yet, but the pace of improvement is hard to ignore. What's still missing, though, is the system that sits between the model and the content. The thing that tells the model *who* you are, *how* you speak, *what* matters in this particular sentence, and *why* that sentence exists in the first place. That's the problem we're working on at Glossia, and I think it's the most interesting one in the space right now.

## Three elements, two we control

When I look at what's needed to enable a genuinely new approach to mono-lingual and multi-lingual content, I see three elements:

1. **Models that are good at languages.** They're not fully there yet, but they're improving fast and we're betting on that trend. We don't need to build a foundation model. We need to be ready to use them well when they get there.
2. **A system to model and share the context that agents need.** This is the piece that sits between the model and the content. The layer that captures your voice, your terminology, your tone, your audience expectations, and serves all of that to the agent in a structured way.
3. **The context that comes from users.** Humans bring judgment, cultural awareness, and creative direction. No system can fully replace that. But a system can make it easy to capture and reuse.

Out of these three, there are two we control: the system itself, and how we guide users to contribute context and help us make the system better. We believe getting both right is what will make Glossia stand out in a space that's quickly filling up with "just plug in an LLM" solutions. The system is where we need to codify decades of linguistic theory into the primitives that are emerging in the agentic world. And the user experience around it is how we make sure the right context actually gets captured, refined, and fed back into the loop.

Eugene Nida, one of the founders of modern translation studies, argued that good translation is not about word-for-word correspondence. His concept of [dynamic equivalence](https://en.wikipedia.org/wiki/Dynamic_equivalence) says that the relationship between the target audience and the translated message should feel the same as the relationship between the original audience and the source. That's a beautiful idea, but it requires deep contextual understanding: who's reading, what cultural frame they bring, what tone the original was going for. These are exactly the kinds of things that need to live somewhere a model can access them.

## What we need to capture, and how

One of the first things we've been exploring is what information needs to be captured, and how to structure it so agents can actually use it. The more we thought about it, the more we realized this wasn't a flat configuration file or a settings page. It needed to be a graph. Specifically, a **[directed acyclic graph](https://en.wikipedia.org/wiki/Directed_acyclic_graph)**.

Why a DAG? Because **context is not flat**. Your brand voice influences your terminology. Your terminology shapes how you write about specific features. Your audience expectations inform the formality level, which in turn affects word choice. These relationships have direction and hierarchy, and they don't loop back on themselves.

There's prior art here. Knowledge graphs have been used for years in AI systems to represent structured relationships between concepts. More recently, [context graphs](https://grokipedia.com/page/context-graph) have extended that idea by adding dynamic context layers, exactly the kind of thing agents need to make informed decisions. And in the multi-agent world, [DAGs have become a foundational pattern](https://santanub.medium.com/directed-acyclic-graphs-the-backbone-of-modern-multi-agent-ai-d9a0fe842780) for modeling task dependencies and information flow.

But here's the part that excites me: **each node in this graph needs to be versioned**. When you change your brand voice, you shouldn't lose access to the previous version. When you update a terminology entry, the system should know which content was produced under the old definition and which pieces might need to be revisited. This is what lets us optimize the agentic workflow so it only triggers for the pieces that are actually impacted by a change, rather than reprocessing everything.

## Bidirectional by design

We believe the relationship between context nodes and content needs to be directional, and it needs to work both ways.

Looking at it from one side: you need to know how content is connected to context. When a piece of context changes (say, your brand voice shifts to be more casual), which blog posts, product descriptions, or help articles were written under the previous version? Those are the ones that need to be revisited or re-translated. This is the **forward direction, from context to content**.

From the other side: when a linguist looks at a piece of content and wonders why a particular choice was made, they should be able to trace it back to the context that guided the decision. What voice definition was active? What terminology rule applied? This **backward traceability** is what lets humans understand what the agents did and iterate on it with confidence.

NASA calls this [bidirectional traceability](https://swehb.nasa.gov/display/SWEHBVB/SWE-059+-+Bidirectional+Traceability+Between+Software+Requirements+and+Software+Design): the ability to follow an association between entities in either direction. It's a principle from systems engineering, and it turns out to be exactly what you need when you're trying to create a feedback loop between linguistic context and generated content.

This bidirectional quality is what makes **progressive refinement** possible. A linguist can review a piece of content, see the context that shaped it, decide that the voice definition needs adjustment, and create that adjustment. The system then knows exactly which other content is affected by the change. It's a tight loop, and it's deeply human.

## Beyond a single repository

There's another dimension to this graph that I find particularly interesting. **It can't live in a single repository.** The context graph needs to be shareable across projects, and potentially across organizations.

Think about it: a company has a brand voice. That voice applies across every product, every website, every support article. It doesn't live in one repo. It's a cross-cutting concern. You might define your core voice at the organization level, then apply overrides at the project level for a specific product or audience. This is **scope inheritance**, the same pattern we're used to in programming, but applied to linguistic context.

And this context needs to be versioned properly. You can't just change the voice definition and wipe out the previous version. There's a lot to learn from how [Git handles versioning](https://www.ephraimsiegfried.ch/posts/git-as-a-fancy-dag) through content-addressable storage and DAGs. Git's model of commits, branches, and diffs is fundamentally about tracking how things change over time while preserving access to every previous state. That's exactly what we need for linguistic context.

In fact, we think a voice change should happen through something we're calling a *voice change request*. Much like a pull request creates a space for discussion around code changes, a voice change request creates a space for discussing linguistic changes. Why are we shifting to a more conversational tone? What impact will that have? Which content will be affected? These are conversations worth having before the change propagates.

## Where humans become more creative, not less relevant

And this is where things start to get really interesting. Instead of eliminating humans, which is the narrative that a lot of people push when they talk about AI, this system **gives humans a more creative role**.

Imagine a team of linguists and content strategists having a session where they discuss ideas about the brand's linguistic direction. They could explore concepts, debate tone shifts, reference cultural context that no model has access to. And then, rather than manually updating hundreds of files, they capture their decisions as adjustments to the context graph. The system takes care of propagation.

Or take it a step further: imagine agentic sessions where a linguist works with an AI assistant to explore linguistic ideas. "What if we made the error messages more empathetic?" The agent simulates the impact, shows how the current context would change, previews what the updated content might look like. The linguist refines, adjusts, and when they're satisfied, submits a context change request. Wouldn't that be something?

**This is not about replacing the linguist.** It's about giving them better tools to do what they're already great at: making nuanced, culturally informed decisions about language. The system handles the mechanical parts (propagation, impact analysis, consistency) while humans focus on the creative parts (voice, tone, cultural resonance).

I keep coming back to what Nida was getting at with dynamic equivalence. The goal is not linguistic accuracy in a mechanical sense. It's about creating the same felt relationship between reader and content, regardless of language. That requires taste, judgment, and cultural awareness. Things that humans are remarkably good at, and that models still struggle with. The system's job is to make sure those human insights are captured, structured, and reusable.

## What's next

In a follow-up post, we'll get more technical and talk about the role that sandboxes will play in enabling experiences that haven't been seen in this space yet, and why we're investing heavily in APIs. There's a whole dimension around staging, previewing, and testing linguistic changes before they go live that we're excited to dig into.

If any of this resonates with you, whether you're a linguist frustrated with the current tooling, a developer who's struggled with localization workflows, or just someone who thinks deeply about how language and technology intersect, we'd love to hear from you.
