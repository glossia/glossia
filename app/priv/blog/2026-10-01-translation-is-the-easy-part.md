%{
  title: "Translation is the easy part",
  slug: "translation-is-the-easy-part",
  summary: "How conversations about languages, software delivery, and trust led María José and me to build Glossia.",
  author: "pedro"
}
---

Languages are a great and underappreciated tool for accessibility and bringing tech products to new markets. When your product speaks to communities whose main language isn't English, you signal that you thought about them. That can establish a very deep connection.

Unfortunately, making your product and brand speak several languages is something many teams can't afford. They often find themselves having to pick two out of three: **quality, speed, and cost**.

If they want translations to keep pace with software delivery, they can invest in a dedicated team of people to maintain quality, but that comes at a cost. Or they can lean more heavily on machine translation, moving fast but accepting lower quality. If they choose quality and low cost, relying on human translation without a dedicated team, they usually sacrifice speed. Along the way, they end up with convoluted systems pushing and pulling translations between their repositories and third-party tools.

Since [large language models](https://en.wikipedia.org/wiki/Large_language_model) emerged, my wife, [María José](https://www.linkedin.com/in/mariajosesalmeron/), and I have talked a lot about whether they could help us stop making those tradeoffs. She loves languages and is deeply embedded in the localization industry. I'm a builder.

Tuist is my main gig. When I tried to translate the product and its marketing surfaces, I found myself dealing with convoluted solutions. None of them kept up with our speed of delivery, and some led to conflicts that were a nightmare to resolve. I had that “this feels wrong” moment many times.

## From conversations to Glossia

Every week, we'd discuss new patterns emerging around the capabilities of language models. We saw more and more developers building their own translation pipelines. At their core, these pipelines prompted a model: source language in, translation out, then keep going.

It felt understandable. That's how we builders operate. But someone closer to languages and the processes around them could see how it might go wrong, from inconsistencies at best to mistranslations at worst.

Developers are moving faster and faster. They can't slow down to introduce a system whose underlying workflows were designed long before the internet, moved into a browser, and still struggle to meet the needs of software teams.

This is how the idea of building Glossia started. On one side, we'd bet on models getting better at languages other than English and at translation. On the other, we'd build a system, initially focused on software content, that felt plug and play. Something running in the background, matching your delivery speed, and giving you confidence that the output is right and ready for production.

Many developers treat translation as a one-prompt solution. Some tokens, English in, translation out, and call it done. But when you talk with them, you realize they don't know whether the output is accurate, captures their organization's voice in that language, or communicates the intended message effectively.

I have a similar pipeline at Tuist, translating into languages like Japanese, and I do so with a huge lack of confidence. Languages aren't logic. We can write tests to ensure the format is correct, but that doesn't tell us **whether the words are right**.

“Translation is the easy part,” as my wife likes to say.

So we embarked on figuring out what the right system could look like. We called it Glossia, and we're starting to open it up to people and organizations interested in helping us iterate on it together.

## Deciding what to translate

The first piece we focused on was helping people decide what to translate. The cost of translation is going down and will continue to go down, but it will never be zero. Organizations should still be selective about the languages they invest in.

Sometimes that choice follows directly from a business decision. Other times, teams have a rough idea of their communities and make an educated guess. We thought there was a lot to learn from the people visiting your websites or using your apps. Their language preferences, combined with information about the regions they use your products from, can give you a better basis for those decisions.

The first feature we landed in Glossia was analytics. Add one line of code to your website, and analytics start flowing into your account. We present that information around the decision you need to make: which languages should you invest in next?

Down the road, we'll explore how to bring experiments into the language dimension of a product. Imagine measuring how often people click a call to action when a page uses different voices in the same language. Wouldn't that be cool? Comparing variants has traditionally gravitated around product and design decisions, but languages are part of the product too.

## From zero to translation

Once you've decided to translate a project, the next step is setting it up. As a developer, I dislike processes that come with a lot of friction. We agreed that going from zero to translation should ideally take one step. That's the level of experience we strive for.

Setup usually involves two things. First, extracting the content from the repository so it can be translated, since it often starts as literal strings in the code. Second, configuring the project to pick the right content based on the language. That might come from the user's device or, in more sophisticated cases, a preference they've chosen.

Automating this reliably a few years ago would have been a nightmare. Things have changed, and agents can be quite effective at it.

The process goes like this: you connect your GitHub repository, select the languages you want to translate into, and, after a while, a pull request opens with the changes. Once you merge it, translations start happening. That's it.

We keep translations in the repository, alongside the format checks and other validations you already run as part of [continuous integration](https://docs.github.com/en/actions/about-github-actions/understanding-github-actions). The translation pipeline feeds the results of those checks back to the translation agent. That removes a whole class of problems where a platform opens a pull request and leaves you to deal with failing checks or merge conflicts.

Combined with other mechanisms for building confidence, this is what can make it possible to merge translations automatically. That's the model we believe in. There's little value in asking a developer to check whether a translation pull request is green and click a button, especially when they can't assess the language themselves. We've always seen that extra ceremony as a sign that the design could be better.

We believe the best translation system is one that works without you having to think about it.

## Translating only what changed

The translation system deserves its own section. Tokens still aren't free. Translating everything all the time is slow, expensive, and a waste of resources.

To solve that, we've built a lock file system that tells us whether something needs translating. We call this **incremental translation**. The idea isn't new: build systems have used it for a long time to avoid recompiling everything on every build. We've adapted it to languages.

The system takes into account all the context that affects a particular translation. Some of that context lives in the repository. Some lives in Glossia and spans multiple repositories. We build a dependency tree and use [Merkle trees](https://en.wikipedia.org/wiki/Merkle_tree) to calculate hashes that tell us whether a translation's inputs have changed.

The lock file preserves that tree. It can explain why something was sent for translation, or why it wasn't, instead of leaving people guessing.

[`L10N.md`](/docs/reference/l10n-md) files provide localization context to our translation agents, much like `AGENTS.md` files provide instructions to coding agents. They support more specific context in nested directories, as well as language overrides at every level.

For information that applies to more than one repository, such as shared terminology, the server is the source of truth. The system makes sure it uses the right context and reflects it in the lock file. When that context changes, we can map the change back to the translations that used it and need to be updated.

## Building confidence in the words

The system is designed to converge toward a level of quality. To get there, we have several tools.

The first is adversarial checks that run after translation. Think of a colleague reviewing the code you've included in a pull request. Here, the checks bring linguistic knowledge into the review. For example, a translation shouldn't add or remove meaning from the source. That can happen because language models don't always produce the same output from the same inputs.

As we learn more from our users and our own research into models and existing systems, we'll add more automated checks to the pipeline. Each one should increase the confidence you can have in a translation.

The idea is to reach a point where you trust the system enough that you don't feel the need to go through every pull request. That confidence depends on both the system and the models. We can help pick models based on the target language, because not all models are equally good at the same languages.

Even with those checks in place, you might need to change a translated piece. It could be a one-off correction, terminology that hasn't been written into the context yet, or one of the many scenarios we're still to encounter.

Someone should be able to contribute those changes straight to the repository. But we also think the system should process those contributions as feedback and suggest how to reconcile them with its context. That might mean adding a term to the glossary or adjusting the voice.

This is something a human can do asynchronously, without interrupting continuous translation. The system should help you make it more effective at its job by learning from what people have to say. We could extend that to people suggesting feedback right from the product. Wouldn't that be cool?

Those corrections also need to be taken into account so future translations don't overwrite them. A stateless translation call has no knowledge of the changes people made before it. In traditional systems, translation memories help fill that role. The need they serve doesn't disappear just because the technology changes.

## Where we go from here

This is Glossia. We already use it to translate Glossia, and I'm working on setting it up to translate Tuist's documentation, marketing site, and dashboard into the languages of our communities.

María José and I are building Glossia in our spare time, following a curiosity that has been part of our conversations for years.

In programming, many people are questioning the role of programmers and how it will evolve. I think the localization industry would benefit from a similar questioning of its assumptions and models. How can we help our industry translate more, faster, and at a lower cost, without compromising quality?

We don't have answers to all the questions yet. But we believe we're heading in the right direction, with the simplicity and attention to craft we like to pour into everything we do.

If this resonates with you, [let's chat](mailto:pedro@glossia.ai).
