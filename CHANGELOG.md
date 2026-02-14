# Changelog

All notable changes to this project will be documented in this file.
## [0.2.0] - 2026-02-14

### Bug Fixes
- fix: make OAuth provider config optional in production

The app should boot even without GitHub/GitLab OAuth credentials set. Only configure providers when the env vars are present.
- fix: default to port 4000 for production, keep 4050 for dev

Kamal proxy expects the app on port 4000. The runtime.exs default was
4050 which caused health checks to fail during deploy.


### Features
- feat: add Phoenix app with OAuth login, docs enhancements, and UI improvements

Replace the Eleventy site with a Phoenix/LiveView app. Add GitHub and GitLab OAuth authentication with accounts, users, organizations, and identities. Improve documentation pages with syntax highlighting, copy buttons, clickable heading anchors, collapsible TOC, and table scroll. Style the flash component as a full-width bar below the header. Make FAQ items collapsible and add a prominent sign-in CTA button in the nav.
- feat: use rounded logo as favicon

Convert logo-squared.png to a multi-size .ico (16x16, 32x32, 48x48)
and add a favicon link in the root layout.
- feat(cli): migrate CLI to Bun and update CI executable builds


### Other
- Lots of changes

## [0.1.0] - 2026-02-12

### Bug Fixes
- fix: prevent code snippet horizontal overflow on mobile

Add max-width: 100vw and box-sizing: border-box to mobile code blocks
so long lines scroll within the block instead of overflowing the viewport.

https://claude.ai/code/session_01UJZim24FwSdGEt6A3GLzAe
- fix: add proper right margin to code snippets on mobile

Remove edge-to-edge negative margin approach for mobile code snippets
and keep them within their container with consistent margins on both
sides.

https://claude.ai/code/session_01K2xSMD985sweMRxEm82KZM
- fix: improve mobile responsive layout to prevent horizontal overflow

- Add overflow-x: hidden on html to prevent horizontal scroll
- Add min-width: 0 to grid children (step, tool-card, feature, config-card) to prevent content overflow
- Add overflow: hidden on config-card to contain code blocks
- Add max-width: 100% to code blocks for proper containment
- Make code blocks edge-to-edge within config cards on mobile for better space usage
- Adjust small phone breakpoint for config card code blocks

https://claude.ai/code/session_0161yaFEs2sRkn1wXsQhyWic
- fix: replace em dashes with commas in blog post

https://claude.ai/code/session_011FXxff8XVFLaVpHDJewZnm
- fix: apply biome formatting
- fix: add group headings to release notes template
- fix: update translate workflow from Bun to Rust
- fix: align post body with hero layout and improve blog post content

Separate .post-body from .container in the post template so the body
content left-aligns within the 1080px container, matching the hero.
Simplify the workflow example to use l10n directly via mise, and explain
why we open PRs instead of pushing to main.
- fix: center blog post content horizontally


### Chores
- chore: add agents guidance and updated translations
- chore: add site/_site build output to gitignore
- chore: add Rust dependency caching to CI and release workflows


### Documentation
- docs: update README to use Bun instead of npm
- docs: replace Go commands with Bun in README
- docs: update README for Rust rewrite
- docs: add blog post on automating translations with GitHub Actions
- docs: generalize blog post to cover CI automation broadly
- docs: rewrite "why this matters" to reflect non-blocking workflow


### Features
- feat: add first-party tools and website section
- feat: surface tool verification steps
- feat: simplify progress output
- feat: tint progress lines
- feat: show translating and validating activity
- feat: format tool lines
- feat: make website responsive with mobile menu and multi-breakpoint layout

- Add hamburger menu for mobile navigation (hidden nav links now accessible)
- Add 960px tablet breakpoint for intermediate screen sizes
- Add 400px small phone breakpoint for tighter spacing
- Improve code block display on mobile (edge-to-edge, smaller font)
- Allow CLI command items to wrap on narrow screens
- Scale typography and spacing for mobile viewports

https://claude.ai/code/session_01KFZBTTHaxGaD4EHaG5btCw
- feat: reimplement CLI in Bun/TypeScript

Replace the Go implementation with a Bun/TypeScript implementation that
is also compatible with Node.js for Electron embedding. The CLI produces
standalone portable executables via `bun build --compile`.

- Add Bun as a Mise dependency (replaces Go)
- Implement all CLI commands: init, translate, check, status, clean
- Port config parsing (TOML frontmatter), LLM client (OpenAI/Anthropic),
  plan building, validation, lock files, and TUI reporter
- Use only Node.js-compatible APIs (fs/promises, crypto, child_process)
  so the code runs in both Bun and Node.js/Electron
- Update release workflow to build Bun standalone binaries per platform
- Dependencies: @iarna/toml, js-yaml, minimatch

https://claude.ai/code/session_01RjLfQQg7nhT9YuTjvo8ooK
- feat: add CI workflow and tests

Add a GitHub Actions CI pipeline that runs typecheck, tests, and build
on every push/PR to main. Add unit tests for config parsing, validation,
checks, hashing, format detection, and output expansion.

https://claude.ai/code/session_01RjLfQQg7nhT9YuTjvo8ooK
- feat: add format checking with Biome

Add Biome formatter with format:check CI step. Auto-format all source
files to consistent style (2-space indent, double quotes, semicolons,
trailing commas, 100 char line width).

https://claude.ai/code/session_01RjLfQQg7nhT9YuTjvo8ooK
- feat: add Progressive Refinement section to homepage

Explain that translations improve iteratively through human review cycles,
drawing on prior art from Kaizen, PEMT, and successive approximation.
Includes vertical timeline UI and translations for all 6 supported languages.

https://claude.ai/code/session_014yfYCnE79UtYxh7rPrSNBs
- feat: add blog section with SEO support and first blog post

Add a complete blog infrastructure: listing page at /blog/ with pagination
for all locales, SEO meta tags (Open Graph, Twitter Cards, JSON-LD structured
data, canonical URLs), navigation links, and a homepage blog section.

The first post covers why l10n was built — the overhead of syncing content
with external platforms, the CI failures from tools that can't validate,
the conversation with María José that sparked the agent-based approach,
and the vision for a human input experience beyond the terminal.

https://claude.ai/code/session_011FXxff8XVFLaVpHDJewZnm
- feat: update blog post with install instructions and open source closing

- Fix Maria Jose's GitHub handle to @mjsesalm
- Add "Get started" section with CLI install and setup instructions
- Replace closing with message about l10n being free, open source,
  and treated with the same product-level care as Tuist

https://claude.ai/code/session_01NodfLj4Tzcfw6zhssP8nky
- feat: add experimental phase warning admonition to README

https://claude.ai/code/session_01L2isFCmuDDeeTPMUANrqjd
- feat: unify CLI output with right-aligned verb format

Replace the inconsistent Reporter interface (info, tool, activity,
status, cleanRemoved, etc.) with three primitives: log(verb, message),
step(verb, current, total, message), and progress(verb, total).

Every output line now follows the same format: right-aligned verb in a
12-char column, bold + colored, followed by the message. Uses standard
ANSI 16-color instead of 256-color. On TTY, step() overwrites in place
with \r for live progress; on CI each step prints a new line.
- feat: colorize CLI output with richer message formatting

Add color to the message portion of CLI output, not just the verb:
- Dim file paths for reduced visual noise
- Cyan arrows between source and output paths
- Magenta language codes in parentheses
- Color-coded summary numbers (green ok, yellow stale, red missing)
- Dimmed step counters [N/N]
- Zero-count summary values dimmed for quick scanning

All color respects --no-color flag and NO_COLOR env, and only
activates on TTY terminals.
- feat: add square OG image and twitter card meta tags
- feat: make coordinator agent agentic with tool use

When a coordinator model is configured, the coordinator now runs as
a proper agentic loop that calls tools to translate, validate syntax,
check preserved tokens, and retry on failures. This replaces the
single-shot brief generation with an iterative process where the
coordinator decides how to fix validation errors.

Adds chat_with_tools() for both Anthropic and OpenAI providers,
a full tool registry (translate, validate_syntax, validate_preserve,
validate_po, run_check_command), thorough PO/POT validation with
header/plural-forms/format-string checks, and .pot file support.

The non-agentic path (no coordinator model) is preserved exactly.
- feat: rewrite `l10n init` with Agent Client Protocol (ACP)

Replace the dialoguer-based language picker with ACP integration
that delegates initialization to an external AI coding agent
(Claude Code, Gemini CLI, Goose, etc.). The agent scans the
project, converses with the user, and generates a fully working
L10N.md configuration.
- feat: add Gemini support, auto-validation, token tracking, and reliability improvements

Add Gemini provider auto-detection from model names with correct API
endpoint configuration. Add auto-validation in the translate tool to
reduce coordinator round-trips. Track and display token usage totals.
Improve reliability with code fence stripping, empty response retries,
incremental lock file writes, and better error diagnostics.


### Other
- Build l10n CLI, site, and Anthropic support
- Improve CLI UX with Charm and progress
- Add git-cliff release automation
- Fix git-cliff config regex
- Fix release workflow git-cliff install
- Adjust git-cliff tags for mise compatibility
- Simplify release notes body
- Drop version from release artifact names
- Add l10n tool to mise config
- Show completed files in progress output
- Add Cloudflare Workers deploy workflow
- Add emojis to README headings
- Add init command and path flag
- Rename release workflow to deploy
- Restore release workflow and deploy site
- Merge pull request #1 from tuist/claude/make-website-responsive-As32c
- Merge pull request #3 from tuist/claude/fix-code-snippet-overflow-Re9Jo
- Merge pull request #2 from tuist/claude/cli-bun-reimplementation-xzq8x
- Merge pull request #4 from tuist/claude/fix-mobile-snippet-margin-KEY2k
- Merge pull request #5 from tuist/claude/fix-mobile-responsive-Y0HcQ
- Merge pull request #6 from tuist/claude/add-translation-improvement-section-zgqqI
- Merge pull request #7 from tuist/claude/add-localization-blog-post-prJrQ
- Merge pull request #8 from tuist/claude/add-blog-setup-instructions-fBn0o
- Merge pull request #9 from tuist/claude/add-experimental-warning-5CB8Q
- Translate the content
- Merge pull request #11 from tuist/claude/consistent-cli-output

feat: unify CLI output with right-aligned verb format
- Add CI workflow to auto-translate on push to main (#12)

* feat: add TranslateGemma translation path and CI pipeline

Wire up TranslateGemma (via Vertex AI) as the translator and Claude
Sonnet as the coordinator. The ChatMessage content type now supports
the structured array format TranslateGemma expects. A new CI workflow
detects stale translations on push to main and opens a PR with updates.

* fix: address PR feedback on translate workflow

- Use mise-action instead of setup-bun (with caching)
- Use exit code from `status` command instead of grepping stdout
- Pin action SHAs for google-github-actions/auth and jdx/mise-action
- Read Vertex AI endpoint URL from env (VERTEX_AI_ENDPOINT secret)
- Add comment explaining the zh-Hans/zh-Hant lang code mapping

* simplify: use Claude Sonnet 4.5 for both coordinator and translator

Drop TranslateGemma/Vertex AI integration in favor of using Claude
Sonnet 4.5 for both roles. This removes the need for GCP infrastructure,
GPU endpoints, and service account secrets. The only secret needed now
is ANTHROPIC_API_KEY.
- Fix the model used
- Fix panic when truncating multi-byte UTF-8 tool results

The log display was slicing at a byte index, which can land in the
middle of a multi-byte character (e.g. Japanese) and panic.
- Make release commit and tag atomic with the GitHub release

Move the changelog commit, tag, and push to the release job so they
only happen after all build artifacts have been compiled successfully.
The changelog is passed between jobs as an artifact.
- Fix cargo fmt formatting
- Update translations using Gemini 2.5 Flash

Re-translate all content across 6 languages (es, de, ko, ja, zh-Hans,
zh-Hant) using Gemini 2.5 Flash, including the new automating
translations blog post.


### Refactors
- refactor: split CI into separate format, typecheck, test, build jobs

Run each check as an independent parallel job for faster feedback and
clearer failure signals.

https://claude.ai/code/session_01RjLfQQg7nhT9YuTjvo8ooK
- refactor: rewrite CLI from TypeScript/Bun to Rust

Rewrites the entire l10n CLI in Rust for better performance, smaller
binaries (~3.4MB), and native cross-compilation support. All 5 commands
(init, translate, check, status, clean) maintain feature parity with the
TypeScript implementation. Lock file format is fully compatible.

Key changes:
- Replace TypeScript source with Rust (clap, tokio, reqwest, serde)
- Update CI workflow for Rust (fmt, clippy, test, build)
- Update release workflow to use cross for Linux, native cargo for macOS/Windows
- Remove TS tooling (package.json, tsconfig, biome, bun.lock)
- Add Rust as mise dependency

<!-- generated by git-cliff -->
