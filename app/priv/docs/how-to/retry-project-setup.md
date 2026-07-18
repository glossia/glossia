%{
  title: "Retry project setup",
  summary: "Recover a project after setup reports a failure.",
  category: "how-to",
  order: 4
}
---

Use **Retry setup** after fixing the condition that caused a project setup to fail.

## 1. Read the failure

Open the project overview. The setup progress card shows the failure and the latest setup activity.

Common causes include:

- The account has no configured model.
- The provider key is missing or no longer valid.
- The Glossia GitHub App cannot access the repository.
- The repository could not be prepared or checked.

## 2. Fix the prerequisite

For model problems, open **Settings** and **Models**. For repository access problems, update the Glossia GitHub App installation in GitHub and grant it access to the repository.

## 3. Retry

Return to the project overview and select **Retry setup**.

The card returns to **Pending**, then **Running**, and shows new activity as work proceeds. Retry is available only while the project is in **Failed** state, which prevents two setup attempts from running at the same time.

## 4. Review completion

When the state changes to **Completed**, review the resulting pull request in GitHub. If it fails again, use the new activity in the card rather than the previous attempt to identify the next action.
