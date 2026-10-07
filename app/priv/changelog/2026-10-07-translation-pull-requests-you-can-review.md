%{
  title: "Translation pull requests you can review",
  summary: "One pull request per project that stays current, fewer pushes to your CI, Markdown that comes back exactly as you wrote it, and a description that explains the translation work."
}
---

We reworked how Glossia delivers translations to your repository. Reviewing what Glossia changed should take minutes and shouldn't tie up your continuous integration runners.

### One pull request that stays current

Each project now has a single translation pull request. When you push new content to your default branch, Glossia adds the translations to the open pull request instead of opening another one. Glossia translates only the content that changed since the last run, because it reads the lockfiles already on that branch. Once you merge or close the pull request, the next change opens a new one.

### Fewer pushes to your CI

Glossia used to push every translated file as soon as it was ready. Each push started your pull request checks, so a large run could start hundreds of check runs. Glossia now groups files into one commit for every 25 files or every 15 minutes, and pushes once more when the run ends. A 150-file run now takes about 6 pushes instead of 150.

### Markdown that comes back exactly as you wrote it

Glossia now writes each translation back into the exact place its source text came from, without reformatting the document. Code, links, components such as `<.card title="...">`, GitHub alerts such as `> [!NOTE]`, heading anchors such as `{#install}`, list markers, and line breaks stay byte-for-byte identical. Before, some of these came back escaped.

Translations also read more naturally. Glossia sends whole sentences, with links and formatting marked so the model can move them to where the target language puts them. Every request includes the surrounding document and the passages already translated from it, so meaning and terminology stay consistent across a page. Reader-facing component attributes, such as `title`, `details`, and `alt`, are translated too.

### A description that explains the work

The pull request description now summarizes everything Glossia did on that branch, and it updates as files arrive:

- Whether the translation is still running, up to date, or stopped, and why.
- Files translated for each language, with the number of model calls and the average quality score.
- The source commits that were translated, with links to their runs in Glossia.
- Every translated file, grouped by language.
- The glossary terms that guided the translations.
- Files that need attention, with the reason.
- Token usage for each model.

The session page in Glossia also lists every planned file from the start, so you can see what is still queued while a run is in progress.
