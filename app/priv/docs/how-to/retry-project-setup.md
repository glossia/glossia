%{
  title: "Retry project setup",
  summary: "Recover a project after setup reports a failure.",
  category: "how-to",
  section: "translation",
  order: 4
}
---

When automated setup fails, Glossia discards the provisional project so the repository can be selected again. A failure notice may appear in the setup flow, but the failed project and its progress history are not retained.

## 1. Read the failure

Read the failure notice before leaving the setup flow. Common causes include:

- The account has no configured model.
- The provider key is missing or no longer valid.
- The Glossia GitHub App cannot access the repository.
- The repository could not be prepared or checked.

## 2. Fix the prerequisite

For model problems, open **Settings → Models**. For repository access problems, update the Glossia GitHub App installation in GitHub and grant it access to the repository.

## 3. Start setup again

Open **Projects → New project**, select the repository, choose **Automated setup**, and select the target languages again. Follow the new setup attempt until it completes.

If a failed project is still visible and offers **Retry setup**, that action starts another attempt. Do not rely on it remaining available: failed provisional projects are removed during cleanup.

## 4. Review completion

When setup completes, review the resulting pull request in GitHub. See [Project setup](/docs/reference/project-setup) for the lifecycle and cleanup behavior.
