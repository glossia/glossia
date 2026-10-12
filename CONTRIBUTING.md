# Contributing to Glossia

Bug reports, feature discussions, and contributions are welcome. Report security vulnerabilities privately as described in [SECURITY.md](SECURITY.md), not in a public issue or pull request.

## Software license

Glossia is source-available under the [O'Saasy License](LICENSE.md). It permits use, modification, distribution, selling copies, and self-hosting, subject to its terms. It prohibits directly competing hosted, managed, or Software-as-a-Service offerings where Glossia's functionality is the service's primary value. It is not an open-source license.

Third-party components retain their existing licenses. Do not remove their notices or submit material you do not have permission to contribute.

## Contributor agreement

External code and documentation contributions require explicit acceptance of the [Contributor License Agreement](CLA.md). You retain copyright in your work. The agreement grants the project owner commercial hosting, sublicensing, and future relicensing rights, including the ability to release your contribution under proprietary terms.

Read the agreement before accepting it. Check the acceptance box in your pull request description, or post the acceptance statement specified in the agreement. If you contribute on behalf of an employer, confirm that you are authorized to grant these rights. Identify any other contribution owners and third-party material in the pull request.

The agreement is currently a draft pending legal review. Maintainers must complete that review before merging external code or documentation in reliance on it. Acceptance is reviewed manually; no automated signing or verification service is configured.

The agreement does not apply retroactively. Maintainers must separately establish the rights to previously accepted contributions rather than assuming this agreement covers them.

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

- Confirm the contributor agreement has completed legal review.
- Confirm every owner of the contributed material has explicitly accepted the applicable agreement or provided a reviewed equivalent grant.
- Preserve the acceptance record in the pull request. Record the agreement version and revision being accepted; request renewed acceptance if its terms change before merge.
- Check third-party licensing and confidentiality separately. An agreement is not a substitute for reviewing submitted content.
