%{
  title: "Content ownership and portability",
  summary: "Why repository-owned content matters, and which dependencies public source does and does not remove.",
  category: "explanation",
  section: "translation",
  order: 3
}
---

A company should be able to change its language tooling without losing the content it has already produced or the ability to ship that content.

## Ownership is more than an export button

Exporting translated files is useful, but portability also includes the review history, language guidance, terminology, and configuration needed to continue the work. If those live only inside one proprietary workspace, the company may retain its output while losing the process that produced it.

Glossia's repository workflow keeps published source and translated files in Git. Pull-request history remains with the repository, and file-based configuration describes the transformation independently of a browser editing session.

## Language decisions should be reusable

Voice and glossary guidance capture organizational intent. Glossia makes that context available to humans and integrations, including agents through MCP. This is a different kind of reuse from looking up a previously translated segment: it can guide new content even when there is no matching sentence in a memory.

That does not make segment-based translation memories obsolete. Teams may have valuable reviewed translations and specialist workflows they want to retain. Glossia's position is that such resources should complement a company's delivery process rather than become a mandatory proprietary authority over it.

## Public source helps, but is not a magic exit plan

Being able to inspect and modify the implementation helps teams understand how their content is processed. It does not mean every operational dependency disappears. A deployed Glossia instance still needs databases, model-provider access for relevant workflows, credentials, and infrastructure. Dashboard-managed language context also needs an explicit migration plan if a team changes systems.

The current O'Saasy license restricts competing hosted services. Public source availability is not the same as an unrestricted open-source license or an assurance that a replacement service can be operated under any business model. See the repository's [license](https://github.com/glossia/glossia/blob/main/LICENSE.md).

## A useful portability test

Ask whether the team can still inspect, review, and publish its existing translated content if the language service is unavailable. With repository-owned outputs, publication does not require reopening a proprietary editor just to recover the latest file.

Then ask how language guidance, credentials, and automation would move to another system. Those are separate questions, and keeping them explicit is more useful than promising "no lock-in" without qualification.
