# Changelog

All notable changes to this project will be documented in this file.

## NEXT

### Features

### Bug Fixes

## 0.14.1 - 2026-02-14

### Bug Fixes
- Rename binary inside release archives from platform-specific name to just `glossia`.
- Strip macOS quarantine xattr from binaries before packaging.

## 0.14.0 - 2026-02-14

### Features
- Add local release script and manually-maintained changelog workflow.

## 0.2.0 - 2026-02-14

### Bug Fixes
- Make OAuth provider config optional in production. The app should boot even without GitHub/GitLab OAuth credentials set. Only configure providers when the env vars are present.
- Default to port 4000 for production, keep 4050 for dev. Kamal proxy expects the app on port 4000. The runtime.exs default was 4050 which caused health checks to fail during deploy.

### Features
- Add Phoenix app with OAuth login, docs enhancements, and UI improvements. Replace the Eleventy site with a Phoenix/LiveView app. Add GitHub and GitLab OAuth authentication with accounts, users, organizations, and identities. Improve documentation pages with syntax highlighting, copy buttons, clickable heading anchors, collapsible TOC, and table scroll. Style the flash component as a full-width bar below the header. Make FAQ items collapsible and add a prominent sign-in CTA button in the nav.
- Use rounded logo as favicon. Convert logo-squared.png to a multi-size .ico (16x16, 32x32, 48x48) and add a favicon link in the root layout.
- Migrate CLI to Bun and update CI executable builds.

## 0.1.0 - 2026-02-12

### Bug Fixes
- Prevent code snippet horizontal overflow on mobile.
- Add proper right margin to code snippets on mobile.
- Improve mobile responsive layout to prevent horizontal overflow.
- Replace em dashes with commas in blog post.
- Apply biome formatting.
- Add group headings to release notes template.
- Update translate workflow from Bun to Rust.
- Align post body with hero layout and improve blog post content.
- Center blog post content horizontally.
- Fix panic when truncating multi-byte UTF-8 tool results.

### Features
- Add first-party tools and website section.
- Surface tool verification steps.
- Simplify progress output.
- Tint progress lines.
- Show translating and validating activity.
- Format tool lines.
- Make website responsive with mobile menu and multi-breakpoint layout.
- Reimplement CLI in Bun/TypeScript.
- Add CI workflow and tests.
- Add format checking with Biome.
- Add Progressive Refinement section to homepage.
- Add blog section with SEO support and first blog post.
- Update blog post with install instructions and open source closing.
- Add experimental phase warning admonition to README.
- Unify CLI output with right-aligned verb format.
- Colorize CLI output with richer message formatting.
- Add square OG image and twitter card meta tags.
- Make coordinator agent agentic with tool use.
- Rewrite `glossia init` with Agent Client Protocol (ACP).
- Add Gemini support, auto-validation, token tracking, and reliability improvements.

### Refactors
- Split CI into separate format, typecheck, test, build jobs.
- Rewrite CLI from TypeScript/Bun to Rust.

### Documentation
- Update README to use Bun instead of npm.
- Replace Go commands with Bun in README.
- Update README for Rust rewrite.
- Add blog post on automating translations with GitHub Actions.
- Generalize blog post to cover CI automation broadly.
- Rewrite "why this matters" to reflect non-blocking workflow.

### Chores
- Add agents guidance and updated translations.
- Add site/_site build output to gitignore.
- Add Rust dependency caching to CI and release workflows.
