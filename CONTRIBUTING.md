# Contributing to Glossia

Bug reports, feature discussions, and contributions are welcome. Report security vulnerabilities privately as described in [SECURITY.md](SECURITY.md), not in a public issue or pull request.

## Software license

Glossia follows an open-core model. Code outside `ee/` is licensed under [Apache-2.0](LICENSE-APACHE), subject to the exceptions in [LICENSE.md](LICENSE.md). You may use it commercially, self-host it, and offer hosted services under that license. Material under `ee/` is source-available under the [Glossia Enterprise License](ee/LICENSE.md), with separate permission required for production use.

Third-party components retain their existing licenses. Do not remove their notices or submit material you do not have permission to contribute.

## Contributor agreement

**Core-only contributions do not require a CLA.** Unless explicitly stated otherwise, contributions outside `ee/` are submitted under Apache-2.0.

Contributions to `ee/` require explicit acceptance of the [Glossia Enterprise Contributor License Agreement, Version 2](CLA.md). You retain copyright; the agreement grants the project owner commercial-use, sublicensing, patent, and future relicensing rights for your enterprise contributions only. If you contribute on behalf of an employer, confirm that you are authorized to grant these rights. Identify other contribution owners and third-party material in the pull request.

The Enterprise CLA workflow checks added, modified, deleted, and renamed `ee/` paths, including renames out of the directory. It does not run CLA Assistant for core-only pull requests. For a mixed core/enterprise pull request, CLA Assistant checks all commit authors, but the agreement covers only their contributions to `ee/`. Split unrelated core contributions into a separate pull request to avoid unnecessary signature requests.

When the bot asks, read the linked agreement and post this exact comment:

> I have read the Glossia Enterprise CLA, Version 2, and I hereby sign it for my contributions to ee/.

CLA Assistant stores public signature metadata in `signatures/v2/cla.json` on this repository's `cla-signatures` branch, not in the contribution branch. The workflow initializes the file with CLA Assistant's JSON schema plus an `agreement` snapshot containing the exact text, Git blob identifier, immutable commit permalink, version, and signing statement. The action preserves that snapshot while appending signatures. Do not create it manually or submit signature records in a pull request. One signature covers present and future enterprise contributions under Version 2. Comment `recheck` to retry verification.

The agreement remains a draft pending legal review. The workflow fails closed for external enterprise changes while the draft notice is present; it will not collect signatures until maintainers complete legal review and remove that notice. A pull request opened by the project owner (GitHub account ID `663605`) is exempt from an inbound grant only when every commit is authored and committed by that same account and its signature passes verification. The owner-only exemption does not accept a `web-flow` committer. Core-only changes still pass without a CLA. If review changes the terms, bump the agreement version, signing statement, and signature-file path together before collecting signatures. Once signatures exist, any change to the document without a new version fails verification. Automated collection does not establish rights in previously accepted contributions.

### Maintainer workflow setup

The workflow uses a commit-pinned release of [CLA Assistant Lite](https://github.com/contributor-assistant/github-action). Upstream is archived; review security updates or a maintained replacement before upgrading. It uses only GitHub APIs and never checks out or executes pull request code with its write token.

The workflow creates `cla-signatures` from the default branch on first use and writes signature records there using `GITHUB_TOKEN`; no personal access token is needed. Repository rules must permit the action to create and update that branch. Restrict human writes to the signature branch to trusted maintainers and do not merge contribution branches into it. Keep `main` protected. Require the **Enterprise CLA** job as a pull request check; it succeeds without requesting signatures when no `ee/` path is involved. The workflow must be on the default branch before comment events can run it.

CLA Assistant Lite inspects at most 100 commits per pull request, so enterprise pull requests over that limit fail closed and must be split. It also reads only the first 30 discussion comments. If a signing comment falls outside that window, sign on a separate short enterprise pull request, then comment `recheck` on the original; the repository-wide Version 2 signature will be recognized. These upstream limits are reasons to consider a maintained replacement.

Every enterprise commit must have a [GitHub-verified commit signature](https://docs.github.com/en/authentication/managing-commit-signature-verification/about-commit-signature-verification), a linked GitHub author, and matching author/committer identities, except for GitHub's verified `web-flow` committer account when the author is also the authenticated pull request opener. Commits created through GitHub's web interface are signed automatically. Bot exemptions apply only to verified bot commits in a pull request opened by that same bot; email-based bot impersonation is rejected. The workflow rejects unlinked authors, ambiguous attribution, incomplete commit lists, and stale pull request revisions before invoking CLA Assistant. Unsigned email-based impersonation is rejected, but a personal signature still cannot establish employer ownership. Co-author trailers are not independently verified by the archived action; maintainers must review all contribution owners, attribution, and authority separately. A green check is not proof of ownership.

Simultaneous signatures from different pull requests can conflict on the signature file; the action fails rather than overwriting another record. Retry with `recheck`. Use the exact signing statement without trailing whitespace, or comment `recheck` after signing. If the archived action re-runs the wrong check for a fork with a common branch name, push an empty commit or close and reopen the original pull request to trigger its own verification.

## Preparing a pull request

- Follow the relevant `AGENTS.md` instructions.
- Use a Conventional Commit title, such as `fix: preserve translated placeholders`.
- Explain what changed, why it matters, and which checks you ran.
- Keep changes focused and include tests for changed behavior.
- Never include credentials, private customer content, database exports, or sensitive production logs in commits or screenshots.

Relevant checks include:

```sh
# Phoenix application
cd app && mix precommit

# Internal operations application
cd babel && mix precommit

# Command-line interface
cd cli && cargo fmt -- --check && cargo clippy --all-targets --all-features -- -D warnings && cargo test

# Web SDK
cd sdk/web && npm test && npm run build
```

Run these commands from the repository root in separate shells, or return to the root between them.

## Maintainer acceptance checklist

Before merging an external contribution:

- For `ee/` contributions, confirm the enterprise agreement has completed legal review and every owner has signed or provided a reviewed equivalent grant. No CLA is required for core-only changes.
- Preserve enterprise signature records on `cla-signatures` and their linked pull request comments. Request renewed acceptance when the agreement version changes.
- Establish rights in previously accepted material before relicensing or moving it across the core/enterprise boundary.
- Check third-party licensing and confidentiality separately. An agreement is not a substitute for reviewing submitted content.
