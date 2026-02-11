---
title: "Automating translations in CI"
summary: "Every push to main triggers a CI job that detects stale translations and opens a pull request with fresh ones. Here's how to set it up and what we're planning next."
date: 2026-02-11
layout: layouts/post.njk
---

One of the things we cared about from the start with l10n was making translations feel like a natural part of the development workflow. Not something you remember to do before a release. Not a step someone has to trigger manually. Just something that happens, automatically, every time content changes.

The idea is simple: every push to `main` triggers a CI job that checks whether any translations are out of date and, if so, generates fresh ones and opens a pull request. The whole thing runs in about a minute, and it works with any CI system.

## How it works

The flow has three steps, and they map directly to l10n commands.

**1. Check if anything is stale.** Run `l10n status`. This compares the current state of your source files and their translations against the lock files that l10n maintains. If everything is up to date, the job exits early. No wasted compute, no noise.

**2. Translate what changed.** If `l10n status` detects that something is stale, either because a source file changed, context was updated, or a translation is missing entirely, run `l10n translate`. This is where the LLM does its work: reading your source content, applying the context you've written in your `L10N.md` files, and producing translations that respect your project's tone and terminology.

**3. Open a pull request.** If any files changed, create a branch, commit the updated translations, and open a pull request. If a translation PR already exists, update it instead of creating duplicates.

We deliberately open a pull request rather than pushing translations directly to `main`. This gives you a chance to review the output, iterate on the translation context in your `L10N.md` files, and build confidence in the agentic workflow. Once you trust the results enough, the goal is to skip the PR step entirely and commit translations straight to `main`, making the process fully invisible.

You'll also want to skip commits that come from the translation job itself (to avoid infinite loops) and release commits.

## Example: GitHub Actions

Here's a concrete example using GitHub Actions, but the same logic applies to GitLab CI, CircleCI, Buildkite, or any other CI system:

```yaml
name: Translate

on:
  push:
    branches: [main]

permissions:
  contents: write
  pull-requests: write

jobs:
  translate:
    name: Translate
    runs-on: ubuntu-latest
    timeout-minutes: 30
    steps:
      - uses: actions/checkout@v5

      - uses: jdx/mise-action@v2

      - name: Check translation status
        id: status
        run: |
          if l10n status; then
            echo "stale=false" >> "$GITHUB_OUTPUT"
          else
            echo "stale=true" >> "$GITHUB_OUTPUT"
          fi

      - name: Run translations
        if: steps.status.outputs.stale == 'true'
        env:
          ANTHROPIC_API_KEY: ${{ secrets.ANTHROPIC_API_KEY }}
        run: l10n translate

      - name: Create PR with translations
        if: steps.status.outputs.stale == 'true'
        env:
          GH_TOKEN: ${{ secrets.GITHUB_TOKEN }}
        run: |
          if [ -z "$(git status --porcelain)" ]; then
            exit 0
          fi
          BRANCH="l10n/update-translations"
          git config user.name "github-actions[bot]"
          git config user.email "github-actions[bot]@users.noreply.github.com"
          git checkout -b "$BRANCH"
          git add -A
          git commit -m "[l10n] Update translations"
          git push --force origin "$BRANCH"
          gh pr create \
            --title "[l10n] Update translations" \
            --body "Automated translation update." \
            --head "$BRANCH" \
            --base main
```

You'll need to add your LLM API key as a secret in your CI environment. We use Anthropic's Claude, so ours is `ANTHROPIC_API_KEY`. If you're using OpenAI, swap it for `OPENAI_API_KEY` and update your `L10N.md` configuration accordingly.

## Why this matters

Translations should follow the same path as every other automated check in your project. When you push code, your CI runs tests, lints your files, and builds your project. Translations should be part of that same loop.

With this setup, a developer writes content in the source language, pushes to `main`, and within a minute there's a pull request with translations ready for review. No context switching. No remembering to "run the translation step." No external platform to check.

And because l10n validates its own output, running syntax checks, preserve-token verification, and any custom commands you've configured, the translations in that PR have already passed the same quality gates your CI would enforce.

## What's next: turning human reviews into linguistic memory

Today, when a reviewer catches a translation issue and fixes it manually, that knowledge lives only in the git diff. The next time l10n translates a similar phrase, it has no way to know about the correction.

We want to change that. We're exploring how to turn human reviews on translation PRs into linguistic memory that l10n can apply to future translations. The idea is simple: if a reviewer changes "click here" to "tap here" in a mobile context, l10n should learn that preference and apply it going forward.

This isn't about building a traditional translation memory database. It's about capturing the feedback loop that already exists in pull request reviews and feeding it back into the translation context. The corrections are already happening in your repository. We just need to make them stick.

We're still figuring out the right shape for this, but the direction is clear: every human review should make future translations better, automatically.

## Get started

If you want to set this up for your project, install l10n and initialize your config:

```bash
mise use github:tuist/l10n
l10n init
```

Configure your source files and target languages in `L10N.md`, add a translation job to your CI pipeline, and set your API key as a secret. From that point on, every push to `main` will keep your translations in sync.
