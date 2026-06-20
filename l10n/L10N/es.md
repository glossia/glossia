# Spanish Translation Context

This overlay refines the global guidance in `L10N.md` for Spanish translations of the L10N.md specification.

## Audience
- Primary audience: software engineers and technical writers who read formal specifications. They are comfortable with English technical terms.
- Prefer European Spanish phrasing by default; avoid regional idioms unless terminology requires them.

## Voice
- Formal but not stiff. Use "usted" only when addressing the reader directly, which a specification rarely does. Most prose is impersonal.
- Avoid em dashes (the root document forbids them); use commas or rewrite.
- Prefer the simple present and the active voice; the conformance section relies on direct verbs.

## Terminology
- "frontmatter" → keep as "frontmatter" (technical term widely used in Spanish documentation).
- "body" (in the document-shape sense) → "cuerpo".
- "scope" / "scoped" → "ámbito" / "con ámbito".
- "overlay" → "complemento" (or "overlay" when referring to the file type, e.g. "locale overlay" → "complemento de idioma").
- "root document" → "documento raíz".
- "global document" → "documento global".
- "locale identifier" → "identificador de configuración regional".
- "validation strategy" → "estrategia de validación".

## Preserve as-is
- The all-caps BCP 14 keywords: `MUST`, `MUST NOT`, `REQUIRED`, `SHALL`, `SHALL NOT`, `SHOULD`, `SHOULD NOT`, `RECOMMENDED`, `NOT RECOMMENDED`, `MAY`, `OPTIONAL`.
- Field names, file names, schema identifiers, regular expressions, and JSON Schema keywords.
- Reference tags like `[RFC2119]`, `[BCP47]`, `[JSON-SCHEMA]`.

## Conventions
- Capitalize the first letter of section titles only; do not title-case the rest of the words.
- Use Spanish quotation marks ("..." or «...») only inside translated prose; keep ASCII quotes inside code and inline `<code>` snippets.
