---
id: workflow
kind: section
number: "5"
title: 検証ワークフロー
---

<p class="note">[翻訳作業中。] 翻訳が完了するまで、英語版が正本となります。</p>

<p class="note">This section is informative.</p>

An L10N document <span class="kw">MAY</span> declare <code>validation</code> in its
frontmatter to specify a command the translation tool runs after translation is
complete. The typical use is for developers to provide a script that checks the
LLM-generated translation against project-specific rules (length limits, glossary
compliance, balance constraints, formatting invariants) before the output is accepted.

The <code>validation</code> value <span class="kw">MUST</span> be an array of non-empty
strings. The first element is the command; subsequent elements are its arguments. The
shell is not involved — the array elements map directly to OS-level
<code>exec</code> arguments. The translation tool <span class="kw">MUST</span> execute
the command with the directory containing the L10N.md document that declared the
<code>validation</code> as the working directory, or document a different
default.

Before execution, the tool <span class="kw">MUST</span> set the following environment
variables:

<ul>
  <li><code>L10N_SOURCE_PATH</code> — absolute path to the source file</li>
  <li><code>L10N_TARGET_PATH</code> — absolute path to the translated output file</li>
  <li><code>L10N_LOCALE</code> — the target locale identifier (e.g. <code>es</code>, <code>ja</code>)</li>
  <li><code>L10N_DOC_PATH</code> — absolute path to the L10N.md document whose
  <code>validation</code> triggered the command</li>
</ul>

Implementations <span class="kw">MAY</span> provide additional environment variables.
The command <span class="kw">MUST</span> exit with code 0 to signal that the
translation is acceptable; any non-zero exit <span class="kw">MUST</span> be treated as
a failure. The tool <span class="kw">SHOULD</span> pass the command's stderr back to
the translation agent so it can incorporate the diagnostics into a retry, and
<span class="kw">MAY</span> capture stdout for structured reporting.

Validation commands compose through replacement: a scoped document's
<code>validation</code> replaces the root-level command for that scope's files, and a
locale overlay's <code>validation</code> replaces the scoped (or root) command for that
language only. When no <code>validation</code> is declared at any level, the translation
tool <span class="kw">MAY</span> apply built-in checks inferred from file type (e.g.
Markdown parse validity, gettext <code>.mo</code> compilation).
