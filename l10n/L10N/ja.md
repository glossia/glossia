# Japanese Translation Context

This overlay refines the global guidance in `L10N.md` for Japanese translations of the L10N.md specification.

## Audience
- Primary audience: software engineers and technical writers who read formal specifications. They are familiar with English technical terminology.
- Use です・ます調 throughout. Avoid casual endings even in informal-sounding passages.

## Voice
- Maintain the register of a technical specification (仕様書). Sentences should be neutral and precise.
- Avoid translating concepts twice (do not write both katakana and a Japanese gloss). Pick one and stick with it within the document.

## Terminology
- "frontmatter" → カタカナ「フロントマター」.
- "body" (document-shape sense) → 「本文」.
- "scope" / "scoped" → 「スコープ」 / 「スコープ付き」.
- "overlay" → 「オーバーレイ」. ("locale overlay" → 「ロケールオーバーレイ」.)
- "root document" → 「ルートドキュメント」.
- "global document" → 「グローバルドキュメント」.
- "locale identifier" → 「ロケール識別子」.
- "validation strategy" → 「検証ストラテジ」.
- "repository" → 「リポジトリ」.

## Preserve as-is
- The all-caps BCP 14 keywords: `MUST`, `MUST NOT`, `REQUIRED`, `SHALL`, `SHALL NOT`, `SHOULD`, `SHOULD NOT`, `RECOMMENDED`, `NOT RECOMMENDED`, `MAY`, `OPTIONAL`. Do not translate or wrap in quotes.
- Field names, file names, schema identifiers, regular expressions, and JSON Schema keywords.
- Reference tags like `[RFC2119]`, `[BCP47]`, `[JSON-SCHEMA]`.

## Conventions
- Use 全角 punctuation in translated prose (、 。「」). Use 半角 punctuation inside code, JSON, and regular expressions.
- Insert a thin space (or none) between Japanese characters and adjacent Latin script; do not pad with full-width spaces.
- Numbers and version strings stay 半角: `1`, `4.5`, `v1`.
