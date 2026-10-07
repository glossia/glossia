%{
  title: "Calmer translation pull requests",
  summary: "What we learned from letting Glossia loose on a busy repository, and how translation pull requests changed because of it."
}
---

You learn a lot the first time your tool meets a real repository. For us, that was Tuist. Their team merges to `main` many times a day, and Glossia did exactly what we had built it to do: it translated every change and pushed each file as soon as it was ready. The result was a new pull request for almost every merge, each with around 150 commits, and a CI queue full of checks nobody had asked for. Some of their docs pages also came back with components and alerts escaped into plain text. Not the quiet, background experience we keep talking about.

That stung, because we've always said the best translation system is one you don't have to think about. A pull request that floods your CI or mangles your docs is the opposite of that. So we went back and rethought how translations reach your repository.

Glossia now keeps a single pull request per project and grows it as your content changes. It reads the lock files already on that branch, so it only translates what's new, and it pushes in batches instead of file by file. On a repository like Tuist's, that's a handful of pushes where there used to be a hundred and fifty.

We also stopped touching parts of your documents that aren't ours to touch. Glossia used to rebuild every page it translated, and anything it didn't fully understand, like a Phoenix component or a GitHub alert, could come out the other side escaped. Now it only swaps out the sentences it translated and leaves everything else exactly as you wrote it. There was a nice side effect we didn't expect: because the model now sees whole sentences and the rest of the page, the translations read better. In Japanese, a link no longer has to sit awkwardly where it was in the English sentence.

Finally, the pull request now tells you what happened. Which languages and files were translated, from which commits, how they scored, which glossary terms shaped them, and what, if anything, needs your attention. We think of it as the note a careful colleague would leave you before asking for a review.

Thanks to the Tuist team for their patience while we figured this out. If Glossia ever gets in your way like this, we'd love to hear about it.
