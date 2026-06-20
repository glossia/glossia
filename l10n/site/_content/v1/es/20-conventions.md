---
id: conventions
kind: section
number: "2"
title: Convenciones y terminología
---

<p class="note">[Pendiente de traducción.] La versión en inglés es la autoritativa hasta que se complete la traducción.</p>

### 2.1 Requirements Notation {:#requirements-notation:}

The key words <span class="kw">MUST</span>, <span class="kw">MUST NOT</span>,
<span class="kw">REQUIRED</span>, <span class="kw">SHALL</span>,
<span class="kw">SHALL NOT</span>, <span class="kw">SHOULD</span>,
<span class="kw">SHOULD NOT</span>, <span class="kw">RECOMMENDED</span>,
<span class="kw">NOT RECOMMENDED</span>, <span class="kw">MAY</span>, and
<span class="kw">OPTIONAL</span> in this document are to be interpreted as described in
BCP 14 [RFC2119] [RFC8174] when, and only when, they appear in all capitals, as shown
here.

### 2.2 Terminology {:#terminology:}

<dl class="terms">
<dt>Repository</dt>
<dd>The version-controlled project in which L10N documents reside.</dd>
<dt>Document</dt>
<dd>A Markdown file that participates in this standard, classified by its repository path.</dd>
<dt>Frontmatter</dt>
<dd>An optional leading YAML mapping delimited by lines containing only <code>---</code>.</dd>
<dt>Body</dt>
<dd>The Markdown content following the frontmatter; the prose that carries guidance.</dd>
<dt>Root document</dt>
<dd>The repository-wide <code>L10N.md</code>, also called the global document.</dd>
<dt>Scoped document</dt>
<dd>A non-root <code>L10N.md</code> that adds workflow settings to a subtree.</dd>
<dt>Locale overlay</dt>
<dd>A per-language file stored under an <code>L10N/</code> directory.</dd>
<dt>Source language</dt>
<dd>The language strings are authored in, declared by the root document.</dd>
<dt>Locale identifier</dt>
<dd>A language tag as defined by [<a href="#refs-normative">BCP&nbsp;47</a>], with an underscore (<code>_</code>) permitted in place of a hyphen as the subtag separator. See <a href="#schema-shared">Section 4.5</a>. Examples: <code>en</code>, <code>es</code>, <code>zh-Hant</code>, <code>zh_Hant</code>.</dd>
<dt>Validation command</dt>
<dd>
An array of non-empty strings carried by the <code>validation</code> field. The
translation tool <span class="kw">MUST</span> execute it as a command and arguments
against translated output, treating exit code 0 as pass and any non-zero exit as
failure. Before execution the tool <span class="kw">MUST</span> set these environment
variables:
<ul>
  <li><code>L10N_SOURCE_PATH</code> — absolute path to the source file</li>
  <li><code>L10N_TARGET_PATH</code> — absolute path to the translated output file</li>
  <li><code>L10N_LOCALE</code> — the target locale identifier (e.g. <code>es</code>, <code>ja</code>)</li>
  <li><code>L10N_DOC_PATH</code> — absolute path to the L10N.md document controlling the scope</li>
</ul>
Implementations <span class="kw">MAY</span> provide additional env vars. Validation
commands <span class="kw">SHOULD</span> write diagnostics to stderr; stdout
<span class="kw">MAY</span> be captured as structured output by the tool.
</dd>
</dl>
