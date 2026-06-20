---
name: glossia-mobile-review
description: Project-specific PR-review rules for the Glossia mobile app (Expo + React Native) under `mobile/`. Focuses on what only this repo knows — Expo SDK boundaries, secure-store for credentials, i18n via i18n-js, navigation conventions, and the theme module as the single source of styles.
---

# Glossia Mobile Review

This skill is intentionally narrow. **Generic TS/React style, naming,
hook-rule violations, and formatting are already covered by the
project's typecheck and lint in CI — do not flag those.** Focus on
the rules below.

For each finding, cite `path:line` (or `module#export`) and quote the
relevant snippet.

---

## 1. Theme — all styles draw from `mobile/src/theme`

The app centralizes design tokens (colors, spacing, typography) in
`mobile/src/theme`. Styles should consume those tokens, not raw values.

### Flag (Severity: medium)

- A `StyleSheet.create({...})` or inline style that uses raw hex
  colors, raw pixel padding/margins, or raw font sizes when the
  corresponding token exists in `mobile/src/theme`.
- A new screen / component that imports `colors`/`spacing`/`typography`
  from somewhere other than `mobile/src/theme`.

### Do not flag

- Raw values in `assets/` configuration (icons, splash) — those go
  through Expo config, not the theme module.

---

## 2. Secrets — `expo-secure-store` only

Tokens, refresh tokens, and any credential material must live in
`expo-secure-store`. `AsyncStorage`, plain `SecureStore` polyfills,
or in-memory globals are not acceptable.

### Flag (Severity: critical)

- A new path that writes an access token, refresh token, API key, or
  user PII to `AsyncStorage`, a plain file, or a module-level variable
  intended to survive a reload.
- A `console.log` / debug print of token contents (even gated by
  `__DEV__`).

### Flag (Severity: high)

- A new dependency on `@react-native-async-storage/async-storage`
  for credential storage when `expo-secure-store` covers the case.

---

## 3. Auth — go through `mobile/src/auth`

OAuth/PKCE flow uses `expo-auth-session` wired through
`mobile/src/auth`. Screens and API callers must not call
`expo-auth-session` directly.

### Flag (Severity: high)

- A screen that imports from `expo-auth-session` and builds its own
  request/response cycle instead of using the helpers in
  `mobile/src/auth`.
- A token refresh loop implemented in an API call site instead of in
  the shared auth module.

---

## 4. API — go through `mobile/src/api`

All network calls land in the `api` module so headers, auth, base
URL, and error normalization stay consistent.

### Flag (Severity: medium)

- A `fetch(...)` / `axios(...)` call from outside `mobile/src/api`
  that hits the Glossia backend directly.
- A hard-coded backend URL string inside a screen or component when
  `mobile/src/config.ts` already exposes it.

---

## 5. Navigation — typed routes via `mobile/src/navigation`

The app uses `@react-navigation/native-stack` with typed param lists.
Screens push routes through the shared types, not by string.

### Flag (Severity: medium)

- A `navigation.navigate("SomeRoute", {...})` whose route name is
  hard-coded as a free-form string when sibling navigations use the
  typed route enum / param list.
- A new screen added to `screens/` without a corresponding entry in
  the navigator's stack types.

---

## 6. i18n — `i18n-js` + `expo-localization`, no hard-coded strings

User-facing copy goes through `i18n-js`, with locale resolution from
`expo-localization`.

### Flag (Severity: medium)

- A user-facing string (`<Text>Sign in</Text>`) added in a screen or
  component instead of a `t("auth.signIn")` lookup.
- A new translation key added to one locale but not the others.

### Do not flag

- Developer-only / debug strings.
- Logs and analytics event names.

---

## 7. Expo SDK boundaries — don't reach into bare React Native

The app targets the Expo managed/dev-client flow. APIs that require
ejecting to bare React Native are out of bounds without an explicit
plan.

### Flag (Severity: high)

- A new dependency on a library that requires a custom native module
  (e.g. a config plugin written from scratch) without a note in the
  PR description explaining why the Expo SDK alternative doesn't work.

### Do not flag

- Expo config plugins from established libraries (`expo-secure-store`,
  `expo-auth-session`, etc.).

---

## 8. Dev-only screens — gated by `__DEV__` or `mobile/src/dev`

Debug screens, dev menus, and state inspectors live under
`mobile/src/dev` and must not be reachable from production builds.

### Flag (Severity: high)

- A new screen under `dev/` exported into the production navigator
  without an `if (__DEV__)` guard.
- A `console.log` left in production code path (gate behind `__DEV__`
  or remove).

---

## Out of scope (handled elsewhere — do not flag)

- TypeScript syntax errors / `any` usage → `tsc` + lint.
- React hook ordering rules → eslint-plugin-react-hooks.
- Unused imports / variables → lint.

---

## Before submitting findings

For each finding, confirm:

1. The `path:line` is real and the snippet appears in the diff.
2. The category above is one of 1–8; if it isn't, downgrade to
   `uncertain: ...`.
3. Severity is set: **critical** (credential leak), **high** (likely
   bug or security regression), **medium** (convention gap),
   **low** (nice-to-have).
4. **The convention you are enforcing exists in the diff base.** If
   sibling screens/modules don't follow the rule yet, the new code is
   consistent, not a regression. Downgrade to `uncertain: ...`.
   Security findings (rules 2, 3, 8) apply regardless of base-state.
