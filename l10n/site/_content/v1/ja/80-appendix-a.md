---
id: appendix-a
kind: appendix
number: "A"
title: 例
---

<p class="note">[翻訳作業中。] 翻訳が完了するまで、英語版が正本となります。</p>

<p class="note">This appendix is informative.</p>

### A.1 Minimal Root Document {:#example-root:}

<figure class="listing">
<figcaption>Listing 2. Canonical root <code>L10N.md</code></figcaption>

```
{{ referenceVersion.standard }}
```

</figure>

### A.2 Single-File Repository Root {:#example-single-repo:}

A root document that also carries workflow frontmatter, so the repository needs no nested scopes.

<figure class="listing">
<figcaption>Listing 3. <code>examples/single-repo/L10N.md</code></figcaption>

```
{{ referenceVersion.examples.singleRepo }}
```

</figure>

### A.3 Scoped Document {:#example-scoped:}

<figure class="listing">
<figcaption>Listing 4. <code>examples/app/L10N.md</code></figcaption>

```
{{ referenceVersion.examples.scoped }}
```

</figure>

### A.4 Spanish Locale Overlay {:#example-es:}

<figure class="listing">
<figcaption>Listing 5. <code>examples/app/L10N/es.md</code></figcaption>

```
{{ referenceVersion.examples.es }}
```

</figure>

### A.5 Japanese Locale Overlay {:#example-ja:}

<figure class="listing">
<figcaption>Listing 6. <code>examples/app/L10N/ja.md</code></figcaption>

```
{{ referenceVersion.examples.ja }}
```

</figure>
