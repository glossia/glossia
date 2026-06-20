---
id: model
kind: section
number: "3"
title: Document Model
---

There are three document shapes. They share one mental model: state structure in
frontmatter, explain judgment in prose, and add files only when scope demands it. The
normative contract for each shape is the corresponding JSON Schema in
[Section 4](#schema).

### 3.1 General Requirements {:#general:}

An L10N document <span class="kw">MUST</span> be a Markdown file. It
<span class="kw">MAY</span> begin with a frontmatter block; the content after the
frontmatter is the body. Either side <span class="kw">MAY</span> be empty: the body
<span class="kw">MAY</span> be empty when the frontmatter is sufficient on its own, and
the frontmatter <span class="kw">MAY</span> be absent when the document only adds body
context. Each role's schema specifies which keys, if any, remain required.

A document's role <span class="kw">MUST</span> be determined by its repository path, and
the document <span class="kw">MUST</span> validate against the version 1 entry schema
([Section 4.1](#schema-entry)), which requires it to satisfy exactly one of the three
document schemas.

Implementations <span class="kw">MUST</span> ignore frontmatter keys they do not
understand and <span class="kw">MUST NOT</span> reject a document solely because such
keys are present.

### 3.2 Root Document {:#root:}

A repository <span class="kw">MAY</span> contain a root document. When present, its path
<span class="kw">MUST</span> be exactly <code>L10N.md</code> at the repository root. It
<span class="kw">MUST</span> declare <code>source_language</code> as a locale identifier,
and <span class="kw">MAY</span> provide a body giving repository-wide guidance such as
tone, brand terminology, and formatting rules. A root document
<span class="kw">MAY</span> also declare the same workflow frontmatter as a scoped
document (<code>validation</code>, <code>sources</code>, <code>targets</code>); this
lets a small repository describe both its language and its translation workflow in a
single file without introducing nested scopes. A conforming
root document satisfies the schema in [Section 4.2](#schema-global); a minimal example
appears in [Appendix A.1](#example-root) and a single-file repository example in
[Appendix A.2](#example-single-repo).

### 3.3 Scoped Document {:#doc-scoped:}

A scoped document is an <code>L10N.md</code> located in a directory other than the
repository root. Its path <span class="kw">MUST</span> match
<code>^(?!L10N\.md$).+/L10N\.md$</code>. A scoped document <span class="kw">MAY</span>
declare workflow frontmatter: <code>validation</code> (an array of non-empty strings),
<code>sources</code> (a mapping of one or more source patterns to target path
templates), and <code>targets</code> (an array of one or more locale identifiers).
When any of these are declared, they configure how a
translation tool processes the scope. When none are declared, the document acts purely as
a context override for its subtree. The body <span class="kw">MAY</span> be empty when
the workflow frontmatter alone captures the scope's intent. The <code>validation</code>
array, when present, is a command and arguments that the translation tool executes
against translated output (see [Section 2.2](#terminology)). A conforming
scoped document satisfies the schema in [Section 4.3](#schema-scoped); a complete example
appears in [Appendix A.3](#example-scoped).

### 3.4 Locale Overlay {:#doc-locale:}

A locale overlay is a Markdown file whose path <span class="kw">MUST</span> match
<code>^(?:.+/)?L10N/[A-Za-z0-9_-]+\.md$</code>. It <span class="kw">MAY</span> provide
a body and <span class="kw">MAY</span> declare <code>locale</code> as a locale
identifier; when <code>locale</code> is omitted, the locale
<span class="kw">SHOULD</span> be inferred from the file name. An overlay refines
guidance for a single language. It <span class="kw">MAY</span> also declare
<code>validation</code>; no other frontmatter keys are permitted. When a locale overlay
declares <code>validation</code>, that command replaces the scope-level or root-level
validation for that language only. A conforming overlay satisfies the schema in
[Section 4.4](#schema-locale); complete examples appear in [Appendix A.4](#example-es)
and [Appendix A.5](#example-ja).
