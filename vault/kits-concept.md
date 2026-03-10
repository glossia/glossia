---
title: "Kits: Translation Resource Bundles for Linguists"
tags: [product, kits, linguists, mvp]
created: 2026-03-01
---

# Kits: Translation Resource Bundles for Linguists

## Core Idea

Linguists should be front and center in Glossia, the way developers are on GitHub. But linguists don't have source repositories. Instead, they create and curate **Kits** -- themed bundles of translation resources scoped to a domain and language pair(s).

Example: "Medical German Kit" by @maria -- a curated set of glossary terms, style rules, and translation references for medical content from German into Spanish, English, and French.

## Why "Kit"?

- Short (3 characters), memorable, approachable
- Plural "Kits" is natural and clean
- Universally understood -- "translation kit" is immediately clear
- Action-oriented: you grab a kit and start working
- Not pretentious -- works for freelancers and academics alike

Other names considered: Lexicon/Lex, Pack, Folio, Guide, Atlas, Tome, Codex, Vault, Shelf. Kit won on simplicity and approachability.

## What a Kit Contains

### V1: Glossary entries only
Each entry is structured:
- Source term (required)
- Definition / context note (optional)
- Per-target-language: translated term + usage note
- Tags (e.g., "cardiology", "formal", "EU regulatory")

### Future (V2+)
- **Translation memories** -- sentence-level translation pairs validated by the linguist
- **Style guides** -- structured fields: formality level, regional preferences, custom rules
- **Reference notes** -- contextual domain knowledge

## Language Scope

A kit has **one source language and multiple target languages**. The domain expertise is tied to the source content. A linguist who deeply understands German medical terminology can map that knowledge to several target languages. This also enables collaboration -- Maria knows DE>ES, Hans knows DE>EN, they contribute to the same kit.

## Editing Interface

Linguists won't write markdown. The kit editor must be **structured and form-based**:

- Glossary entries as a table view (linguists are comfortable with tabular glossary formats from tools like memoQ and Trados)
- Click a row to expand/edit details
- Form fields for each entry, not free-text
- Style guide fields as structured key-value pairs (V2)

## Social Features

- **Public profile page** shows all kits, bio, languages
- **Stars/bookmarks** for social proof
- **Fork + contribute** model (V2) -- like pull requests for term suggestions
- Usage counts, domain tags, language pair browsing

## MVP Scope (V1)

Ship the smallest thing that makes a linguist's profile page interesting:

1. **Kits with glossary entries** -- name, description, source language, target languages, domain tags, term entries
2. **Public profile page** -- `glossia.com/@handle` shows their kits
3. **Kit detail page** -- browsable/searchable glossary table
4. **Kit editor** -- form-based UI for creating/editing glossary entries
5. **Star/bookmark** -- social proof

### Deliberately NOT in V1
- Forking/contributions (complex, needs conflict resolution)
- Translation memories (need file upload/parsing)
- Style guides (need structured format design)
- Monetization
- Integration with translation workflows

## Differentiator

Traditional CAT tools (memoQ, Trados) have termbases and TMs, but they're private, per-project, locked in proprietary formats. Kits are **public, social, and composable** -- the same shift GitHub made for code.

The value for linguists: building public profile and reputation.
The value for Glossia: a community moat beyond the technology.

## Data Model (Initial Thinking)

```
Kit
  - id (uuid)
  - account_id (belongs_to account -- the owner)
  - handle (unique slug within account, like repo name)
  - name
  - description
  - source_language (e.g., "de")
  - target_languages (array, e.g., ["es", "en", "fr"])
  - domain_tags (array, e.g., ["medical", "cardiology"])
  - visibility (public/private)
  - stars_count (counter cache)
  - timestamps

KitEntry
  - id (uuid)
  - kit_id (belongs_to kit)
  - source_term
  - definition (optional context note)
  - tags (array)
  - timestamps

KitEntryTranslation
  - id (uuid)
  - kit_entry_id (belongs_to kit_entry)
  - language (target language code)
  - translated_term
  - usage_note (optional)
  - timestamps

KitStar
  - id (uuid)
  - kit_id (belongs_to kit)
  - user_id (belongs_to user)
  - unique constraint on (kit_id, user_id)
  - timestamps
```

## Open Questions

- Should kits be ownable by organizations too, or only individual users?
- How do domain tags work -- free-form or from a curated list?
- Should there be a "featured kits" section on the homepage?
- How does search/discovery work -- by language pair, domain, or both?
