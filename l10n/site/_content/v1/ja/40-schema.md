---
id: schema
kind: section
number: "4"
title: ドキュメントスキーマ、バージョン1
---

<p class="note">[翻訳作業中。] 翻訳が完了するまで、英語版が正本となります。</p>

The version 1 contract is defined by the JSON Schema files in <code>schemas/v1/</code>.
Those files are the machine-readable, authoritative form; the tables below state the same
rules so they can be read without parsing JSON Schema. Where a table and its linked file
ever disagree, the file wins.

In every table, <code>path</code> is the document's location in the repository (supplied
by the validator, not written in the file) and <code>body</code> is the Markdown content
after the frontmatter; the remaining properties are the document's YAML frontmatter keys.
Frontmatter keys not listed here are ignored by conforming implementations.

### 4.1 Entry Point {:#schema-entry:}

A document conforms to this standard when it satisfies exactly one of the three document
schemas that follow: the global document ([Section 4.2](#schema-global)), the scoped
document ([Section 4.3](#schema-scoped)), or the locale overlay
([Section 4.4](#schema-locale)). The entry-point schema expresses this as a
<code>oneOf</code> over those three.

<p class="schema-source">Canonical schema: <a href="/schemas/v1/l10n-document.schema.json"><code>schemas/v1/l10n-document.schema.json</code></a></p>

### 4.2 Global Document Schema {:#schema-global:}

The repository root <code>L10N.md</code>. Workflow fields are optional; including them lets a single-file repository describe its language and its translation workflow in one place.

<div class="table-wrap">
<table class="fieldtable">
<thead><tr><th>Property</th><th>Required</th><th>Type</th><th>Rule</th></tr></thead>
<tbody>
<tr><td><code>path</code></td><td>yes</td><td>string</td><td>exactly <code>L10N.md</code></td></tr>
<tr><td><code>source_language</code></td><td>yes</td><td>string</td><td>a locale identifier (<a href="#schema-shared">Section 4.5</a>)</td></tr>
<tr><td><code>validation</code></td><td>no</td><td>array of string</td><td>the command and its arguments; each element non-empty. See <a href="#terminology">Section 2.2</a>.</td></tr>
<tr><td><code>sources</code></td><td>no</td><td>object</td><td>one or more entries; keys are non-empty source path patterns, values are non-empty target path templates (typically containing <code>{locale}</code>)</td></tr>
<tr><td><code>targets</code></td><td>no</td><td>array of string</td><td>one or more locale identifiers; duplicates are not permitted</td></tr>
<tr><td><code>body</code></td><td>yes</td><td>string</td><td>Markdown prose; may be empty</td></tr>
</tbody>
</table>
</div>

<p class="schema-source">Canonical schema: <a href="/schemas/v1/global-document.schema.json"><code>schemas/v1/global-document.schema.json</code></a></p>

### 4.3 Scoped Document Schema {:#schema-scoped:}

A non-root <code>L10N.md</code>. Workflow fields are optional; when omitted, the document acts as a context override for its subtree.

<div class="table-wrap">
<table class="fieldtable">
<thead><tr><th>Property</th><th>Required</th><th>Type</th><th>Rule</th></tr></thead>
<tbody>
<tr><td><code>path</code></td><td>yes</td><td>string</td><td>matches <code>^(?!L10N\.md$).+/L10N\.md$</code></td></tr>
<tr><td><code>validation</code></td><td>no</td><td>array of string</td><td>the command and its arguments; each element non-empty. See <a href="#terminology">Section 2.2</a>.</td></tr>
<tr><td><code>sources</code></td><td>no</td><td>object</td><td>one or more entries; keys are non-empty source path patterns, values are non-empty target path templates (typically containing <code>{locale}</code>)</td></tr>
<tr><td><code>targets</code></td><td>no</td><td>array of string</td><td>one or more locale identifiers; duplicates are not permitted</td></tr>
<tr><td><code>body</code></td><td>yes</td><td>string</td><td>Markdown prose; may be empty</td></tr>
</tbody>
</table>
</div>

<p class="schema-source">Canonical schema: <a href="/schemas/v1/scoped-document.schema.json"><code>schemas/v1/scoped-document.schema.json</code></a></p>

### 4.4 Locale Overlay Schema {:#schema-locale:}

A per-language file under an <code>L10N/</code> directory.

<div class="table-wrap">
<table class="fieldtable">
<thead><tr><th>Property</th><th>Required</th><th>Type</th><th>Rule</th></tr></thead>
<tbody>
<tr><td><code>path</code></td><td>yes</td><td>string</td><td>matches <code>^(?:.+/)?L10N/[A-Za-z0-9_-]+\.md$</code></td></tr>
<tr><td><code>locale</code></td><td>no</td><td>string</td><td>a locale identifier; when present, equals the file name</td></tr>
<tr><td><code>validation</code></td><td>no</td><td>array of string</td><td>same as above</td></tr>
<tr><td><code>body</code></td><td>yes</td><td>string</td><td>Markdown prose; may be empty</td></tr>
</tbody>
</table>
</div>

<p class="schema-source">Canonical schema: <a href="/schemas/v1/locale-overlay.schema.json"><code>schemas/v1/locale-overlay.schema.json</code></a></p>

### 4.5 Shared Definitions {:#schema-shared:}

Reusable definitions referenced by the schemas above. A locale identifier in this
standard is a language tag as defined by [[BCP&nbsp;47](#refs-normative)], with one
accommodation: an underscore (<code>_</code>) <span class="kw">MAY</span> be used in
place of a hyphen as the subtag separator, so that identifiers can serve as filenames
and directory names on systems and tools that disallow hyphens. The
<code>localeIdentifier</code> pattern below is a syntactic approximation that accepts
well-formed [BCP47] tags and their underscore-separated equivalents; consuming
implementations <span class="kw">SHOULD</span> additionally validate against [BCP47]
when stricter checking is required.

<div class="table-wrap">
<table class="fieldtable">
<thead><tr><th>Definition</th><th>Type</th><th>Rule</th></tr></thead>
<tbody>
<tr><td><code>localeIdentifier</code></td><td>string</td><td>a language tag per [<a href="#refs-normative">BCP&nbsp;47</a>], with <code>_</code> permitted as a subtag separator; approximated by <code>^[A-Za-z]{2,3}(?:[-_][A-Za-z0-9]{2,8})*$</code>. Examples: <code>en</code>, <code>es</code>, <code>ja</code>, <code>zh-Hant</code>, <code>zh_Hant</code>.</td></tr>
<tr><td><code>nonEmptyString</code></td><td>string</td><td>at least one character</td></tr>
<tr><td><code>nonEmptyStringArray</code></td><td>array</td><td>each element is a <code>nonEmptyString</code>; minimum one element</td></tr>
<tr><td><code>markdownBody</code></td><td>string</td><td>any string, including empty</td></tr>
</tbody>
</table>
</div>

<p class="schema-source">Canonical schema: <a href="/schemas/v1/shared.schema.json"><code>schemas/v1/shared.schema.json</code></a></p>
