%{
  title: "Project setup",
  summary: "States, progress information, and outcomes of repository setup.",
  category: "reference",
  order: 2
}
---

Project setup prepares a connected repository for Glossia. It begins after a user selects a repository and at least one target language in the **New project** flow.

## Prerequisites

- The account has at least one configured model.
- The Glossia GitHub App can access the selected repository.
- The user can create projects in the account.
- At least one target language is selected.

## States

| State | Meaning | Available action |
|---|---|---|
| **Pending** | The project has been accepted and is waiting to start. | Follow progress or leave the page and return later. |
| **Running** | Glossia is inspecting and updating the repository. | Follow the live activity. |
| **Completed** | The localization baseline was prepared and published for review. | Open and review the pull request. |
| **Failed** | Setup could not finish or publish a usable change. | Fix the reported problem and select **Retry setup**. |

Only a failed setup can be retried. A retry moves the project back to **Pending** and starts a new attempt.

## Visible progress

The setup card remains available in the new-project flow and on the project overview. It includes:

- A state badge and progress bar.
- A short explanation of the current state.
- Recent repository preparation, inspection, file-change, check, and completion activity.
- A clear failure message and retry action when recovery is possible.

Progress is stored with the project, so navigating away does not discard it.

## Completed result

A successful connected setup creates a dedicated branch and a pull request against the repository's default branch. The pull request contains the generated localization baseline, including `GLOSSIA.md` context and the smallest practical changes needed to load localized content.

Glossia does not merge the pull request. Repository maintainers review and merge it through their normal GitHub process.
