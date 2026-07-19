%{
  title: "Getting started",
  summary: "Connect a repository and prepare its first localization setup.",
  category: "tutorials",
  order: 1
}
---

This tutorial connects a GitHub repository to Glossia, chooses its first target languages, and prepares a localization baseline for your team to review.

## Before you begin

You need:

- A Glossia account where you can manage settings and projects.
- A GitHub repository you can grant the Glossia GitHub App permission to read and update.
- A provider key for a supported [large language model](https://en.wikipedia.org/wiki/Large_language_model).

## 1. Configure an account model

Open **Settings**, then **Models**, and select **New model**.

1. Give the model a short handle, such as `translation-default`.
2. Open the model picker and type part of a provider or model name to filter the list.
3. Select the model you want Glossia to use.
4. Enter the provider key and save the model.

The handle lets repositories refer to this account model without placing provider credentials in source control. See [Configure a model provider](/docs/how-to/configure-a-model-provider) for more detail.

## 2. Start a project

Return to **Projects** and select **New project**.

If Glossia asks for repository access, follow the link to GitHub and grant the Glossia GitHub App access to the repository. After returning to Glossia, reopen **New project** if necessary.

## 3. Choose a repository

Select the repository you want to localize. Glossia only lists repositories available through the current account's GitHub App installation.

Continue to the language step.

## 4. Choose target languages

Select one or more languages that should be produced from the repository's source content, then start setup.

## 5. Follow setup progress

Keep the setup page open while Glossia prepares the project. The progress card shows the current state and recent activity, including repository preparation, file inspection, changes, checks, and completion.

You can leave the page and return to the project overview without losing the setup state. If setup fails, the same card explains what needs attention and offers **Retry setup**.

## 6. Review the result

When setup completes, open the project overview and review the pull request created for the repository. The proposed baseline normally includes:

- A root `GLOSSIA.md` file with source language, source paths, and target languages.
- The smallest application or content changes needed to load localized files.
- Any lightweight validation that was already available in the repository.

Review and merge the pull request through your normal GitHub workflow. Future translation runs use the merged `GLOSSIA.md` context.

## Next steps

- [Add a new language](/docs/how-to/add-a-new-language)
- [Understand project setup states](/docs/reference/project-setup)
- [Learn how account models work](/docs/explanation/account-models)
