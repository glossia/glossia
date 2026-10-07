%{
  title: "Calmer translation pull requests",
  summary: "Glossia now keeps one pull request per project, pushes far less often, leaves your Markdown alone, and tells you what it did."
}
---

Tuist was one of the first teams to let Glossia open pull requests on a busy repository, and it didn't go well. Every merge to `main` opened a new translation pull request with around 150 commits, one per file. Each commit kicked off their checks, and within a day we had filled their CI queue. On top of that, some docs pages came back with escaped components (`\<.home_card\>`) and alerts (`\[\!NOTE\]`). Sorry about that, Tuist folks. Here's what we changed.

**There's one translation pull request per project now.** New content on your default branch gets added to the pull request that's already open, and since Glossia reads the lockfiles on that branch, it only translates what changed. Merge it or close it, and the next change starts a fresh one.

**We push in batches.** Glossia commits every 25 files or every 15 minutes, plus once at the end. A run like Tuist's goes from about 150 pushes to about 6.

**We stopped rewriting your Markdown.** Glossia used to rebuild every translated page, and anything the Markdown renderer didn't recognize got escaped. Now it only replaces the sentences it translated, so components, alerts, `{#anchors}`, code, and links stay exactly as you wrote them. As a bonus, the model now sees whole sentences and the rest of the page, so the translations read better too. In Japanese, for example, links and code can now move to where they belong in the sentence.

**The pull request tells you what happened.** Instead of boilerplate, the description shows the languages, files, and source commits that were translated, quality scores, the glossary terms that were applied, anything that failed, and how many tokens it took. It updates while the run is going.
