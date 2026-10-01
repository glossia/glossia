%{
  title: "Project setup",
  summary: "States, progress information, and outcomes of repository setup.",
  category: "reference",
  section: "translation",
  order: 2
}
---

Project setup prepares a connected repository for Glossia. After a user selects a repository in the **New project** flow, they choose one of two setup modes.

## Setup modes

| Mode | What Glossia does | When to choose it |
|---|---|---|
| **Automated setup** | Inspects the repository and opens a pull request with the generated `L10N.md` configuration for the selected target languages. | The repository has no localization configuration yet. |
| **Manual configuration** | Creates the project immediately. It does not inspect the repository, change it, or open a pull request. | The repository already has an `L10N.md` file, or a maintainer will write it. |

The states, progress information, and pull request described below apply to automated setup only.

## Manual configuration

A manually configured project has no setup state. It is usable as soon as it is created and is never discarded by a failed setup.

Glossia starts a translation run on the next push to the repository's default branch. The run translates into every target declared in the repository's [`L10N.md`](/docs/reference/l10n-md) files, because no target languages are selected in the **New project** flow.

Until the first translation run, the project overview shows a notice explaining that Glossia is waiting for a push that includes an `L10N.md` file.

## Prerequisites

- The account has at least one configured model.
- The Glossia GitHub App can access the selected repository.
- The user can create projects in the account.
- For automated setup, at least one target language is selected.

## States

| State | Meaning | Available action |
|---|---|---|
| **Pending** | The project has been accepted and is waiting to start. | Follow progress or leave the page and return later. |
| **Running** | Glossia is inspecting and updating the repository. | Follow the live activity. |
| **Completed** | The localization baseline was prepared and published for review. | Open, review, and merge the pull request. |

Projects are provisional while setup is **Pending** or **Running**. If setup cannot finish or publish a usable change, Glossia cleans up the setup environment and deletes the provisional project. The repository then becomes available in the **New project** flow so setup can be attempted again.

## Visible progress

The setup card remains available in the new-project flow and on the project overview. It includes:

- A state badge and progress bar.
- A short explanation of the current state.
- Recent repository preparation, inspection, file-change, check, and completion activity.
- A clear failure message when setup cannot complete.

Progress is stored while the provisional project exists. A terminal failure discards both the project and its visible setup progress.

## Completed result

A successful connected setup creates a dedicated branch and a pull request against the repository's default branch. The pull request contains the generated localization baseline, including `L10N.md` context and the smallest practical changes needed to load localized content.

Setup does not publish header-only target catalogs. When a localization framework requires target catalogs before translation, the catalogs contain the extracted source message entries with empty translation values. When target catalogs are not required yet, setup leaves them for the first translation run.

Glossia does not merge the pull request. Repository maintainers review and merge it through their normal GitHub process.

The project overview shows a setup notice while this pull request is open. The notice is removed after the pull request is merged. If the pull request is closed without being merged, the overview explains that it must be reopened before setup can be considered finished.
