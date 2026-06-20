---
id: conformance
kind: section
number: "6"
title: Conformidad
---

<p class="note">[Pendiente de traducción.] La versión en inglés es la autoritativa hasta que se complete la traducción.</p>

A *conforming document* is a Markdown file whose path matches one of the document
patterns in [Section 3](#model) and that validates against the version 1 entry
schema ([Section 4.1](#schema-entry)).

A *conforming repository* <span class="kw">MUST</span> contain at most one root
document, located at <code>L10N.md</code>, and every file whose path matches a document
pattern <span class="kw">MUST</span> be a conforming document. A validating tool
<span class="kw">MUST</span> treat a schema validation failure as an error and
<span class="kw">SHOULD</span> report the offending path and the failing constraint.
