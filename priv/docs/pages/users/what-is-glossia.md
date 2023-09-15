# Glossia

## What

Glossia stands as your premier localization copilot for online content. By interpreting both the content and its inherent context as a graph of interconnected nodes, we utilize cutting-edge AI technologies to deliver rapid, superior-quality, and economical localizations.

## Why

Traditionally, teams faced a tough choice: pay a premium for human translation or settle for the inconsistent quality of machine translation. Why not blend the strengths of both? Many emerging tools, catering to organizations with vast content or those offering localization features, mistakenly viewed the challenge as linear. This misconception gave birth to solutions that were indirect, cumbersome, lacked adaptability, and came at a steep price. Further complicating the scene, the industry gravitated towards closed-door development and vendor exclusivity, stifling innovation. The consequence? A vast expanse of the internet's content remains untranslated, rendering it linguistically unreachable for many.

## Why now

At Glossia, we envision our role analogous to what [compilers](https://community.glossia.ai/t/building-a-languages-compiler/22) do for computers. Compilers translate code into binaries, transforming intricate webs of dependencies and relationships into optimized versions for specific platforms. Similarly, Glossia deciphers language, but with a unique twist.

While compilers approach code with strict logic, translating human languages isn't as straightforward. Unlike the precise rules in coding, spoken and written languages brim with cultural nuances and linguistic subtleties that often defy conventional logic. However, the advent of AI has been revolutionary. For the first time, we possess technology that can grasp these linguistic intricacies, thanks to advanced models that are continually enriched by the feedback from linguistic experts. **With AI, a 'compiler' for human languages isn't just a dream—it's our reality.**

## Comparison

One might naturally draw parallels between Glossia and other translation platforms, such as [Phrase](https://phrase.com/), or well-known translation tools like [Google Translate](https://translate.google.com/) and [DeepL](https://www.deepl.com/). However, the underlying philosophies and mechanisms are distinctly different.

Traditional localization platforms often **operate under the presumption that translation is a linear problem**, demanding linear solutions. We argue that this perspective often leads to complex, indirect solutions. On the contrary, Glossia champions **a context-centric approach.** We firmly believe that context is paramount. As a result, Glossia offers tools designed to seamlessly capture and interlink context from varied sources. For instance, if your organization plans a multi-channel marketing campaign – spanning across code repositories, CMS, Figma, etc. – all you need to do is provide the context once. Glossia then orchestrates the rest. Furthermore, should the context evolve, Glossia identifies content relying on that context and recommends re-localization. It's the transformative power of context, and its impact becomes palpable once witnessed.

Now, turning our attention to tools like Google Translate and DeepL: while they might offer top-tier translations for isolated content, **their capability to imbibe broader context is limited**. They might fall short in tailoring translations to resonate with, say, the playful language of video games or the joyful nuances of celebratory messages. This is where [Language Learning Models (LLMs)](https://en.wikipedia.org/wiki/Large_language_model), like those developed by [OpenAI](https://openai.com/chatgpt), truly come into their own.

**Why is this distinction essential for your organization?** With advanced tools, content segmentation gains new facets, such as age-specific targeting or geographical personalization. Previously, the limitations of speed and cost made such segmentation a lofty dream. However, as technology advances, increasing speed while driving down costs, we foresee not only the feasibility but also the tools to evaluate impact—allowing practices like A/B testing to extend beyond just design, encapsulating language itself. After all, language is an integral component of the product experience, isn't it?

## Open source

Glossia stands as a proud testament to the [open-source](https://en.wikipedia.org/wiki/Open_source) ethos. For those rooted in the localization industry, our commitment to open source may seem unconventional, akin to generously sharing trade secrets. Yet, the broader software world has consistently debunked this notion. It's evident that much of today's cutting-edge innovation and the bedrock of our digital infrastructure stem from open-source endeavors.

We posit that this very paradigm shift is overdue in the localization landscape, especially given the exciting emergence of Language Learning Models (LLMs) as a foundational technology. Open source isn't merely a distribution model; **it's a crucible for collaboration and diverse discourse.** Despite the rich diversity inherent in the localization industry, certain voices tend to dominate the narrative. Glossia aims to recalibrate this balance, offering a platform where myriad perspectives converge, and a community where everyone feels empowered to shape the future of localization.

Our belief is twofold: open source not only **democratizes but also ignites inspiration.** We envision catalyzing a new wave of tools — tools that willingly unveil their APIs, ardently champion interoperability through standards, and embrace a culture of shared knowledge. In fostering such a collaborative ecosystem, we anticipate benefits that ripple across the sector, ushering in an era where localization tools parallel the quality and dynamism characteristic of today's best software solutions.

## Plans

Contrary to popular belief, open source doesn't equate to 'free of charge'. Maintaining and advancing Glossia demands full-time dedication, and that requires resources – both to compensate our dedicated team and to sustain the infrastructure that powers the software. To support these needs, we've crafted a range of plans aimed at ensuring the continued growth and vitality of the project. The best plan for you will hinge on your specific requirements, but we're confident there's an option that aligns with your organization's needs. For clarity, here's a comparison table to guide your choice:

| Feature              | Status    | Community               | Cloud                     | Enterprise                      |
| -------------------- | --------- | ----------------------- | ------------------------- | ------------------------------- |
| **Hosting**          | Available | You                     | Us                        | You                             |
| **LLMs**             |           |                         |                           |                                 |
| OpenAI ChatGPT       | Available | ✅                      | ✅                        | ✅                              |
| Azure ChatGPT        | Planned   | ◻️                      | ✅                        | ✅                              |
| **Content Sources**  |           |                         |                           |                                 |
| GitHub               | Available | ✅                      | ✅                        | ✅                              |
| GitLab               | Planned   | ◻️                      | ✅                        | ✅                              |
| Figma                | Planned   | ◻️                      | ✅                        | ✅                              |
| Shopify Store        | Planned   | ◻️                      | ✅                        | ✅                              |
| **Fine-tuning**   |           |                         |                           |                                 |
| Glossary | Planned | ◻️                      | ✅                        | ✅                              |
| Context graph | Planned | ◻️                      | ✅                        | ✅                              |
| **Authentication**   |           |                         |                           |                                 |
| Email                | Available | ✅                      | ✅                        | ✅                              |
| GitHub               | Available | ◻️                      | ✅                        | ✅                              |
| SAML SSO (e.g. Okta) | Planned   | ◻️                      | ◻️                        | ✅                              |
| **Access control**   | Planned   | Simple                  | Role-based                | Role-based                      |
| **Apps**             |           |                         |                           |                                 |
| REST API             | Planned   | ◻️                      | ✅                        | ✅                              |
| Webhooks             | Planned   | ◻️                      | ✅                        | ✅                              |
| **Support**          |           | Low-priority via GitHub | Medium-priority via Email | High priority via Slack Connect |
| **Legal terms**      |           | Fixed                   | Fixed                     | Custom                          |

<br/>

> ### Note about enterprise
>
> The enterprise plan operates under a specific license that necessitates a separate agreement. For details, kindly reach out to us at [enterprise@glossia.ai](mailto:enterprise@glossia.ai). Unauthorized hosting of the enterprise version is prohibited, and we will pursue legal remedies if necessary.

## What's next

The subsequent steps depend on your chosen plan. For the Cloud plan, simply sign up on [Glossia](https://glossia.ai) and start your first project. If you've opted for the Enterprise or Community plans, we advise you to consult the [self-hosting guide](./self-host-glossia.md) and follow its instructions.
