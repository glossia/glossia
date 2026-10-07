%{
  title: "Ein Glossar definieren",
  summary:
    "Definieren Sie Begriffe in L10N.md und deren genehmigte Übersetzungen in der jeweiligen Sprach-Override-Datei.",
  category: "Anleitung",
  section: "translation",
  order: 6
}
---
Ihr Team verfügt bereits über Begriffe, die auf eine spezifische Weise übersetzt werden müssen: Produktbezeichnungen, die auf Englisch verbleiben, technische Begriffe mit einer bevorzugten Darstellung, Markenwörter, die einen bestimmten Ton tragen. Definieren Sie sie in Ihrem Repository und Glossia wendet sie für zukünftige Übersetzungen an.

Ein Glossar existiert in zwei Dateitypen, die Sie bereits nutzen:

- `L10N.md` legt fest **Begriffe**: das Wort und seine Bedeutung. Dies gilt für jede Sprache.
- `L10N/<locale>.md` legt fest **Übersetzungen** für eine Sprache. Die Reviewer jeder Sprache sind für ihre eigene Datei verantwortlich.

Wenn Ihr Konto zudem ein Glossar in Glossia hat, werden die beiden bei der Übersetzung zusammengeführt. [Glossar](/docs/explanation/glossary) für die Regeln und zu [wann Sie welches verwenden](/docs/explanation/glossary#when-to-use-which).

## Legen Sie die Begriffe in L10N.md fest

Fügen Sie eine `glossary` europäische Liste an das Frontmatter Ihres Stamm-`L10N.md`:

```yaml
---
source_language: en
sources:
  "docs/**/*.md": "docs/i18n/{locale}/{relpath}"
targets:
  - es
  - ja
glossary:
  - source: commit
    definition: The version-control action of recording changes.
  - source: API
    case_sensitive: true
---

Write for software developers.
```

Jeder Begriff benötigt ein `source`, das Wort, wie es in Ihrem Text erscheint. Ein `definition` hilft dem Modell zu entscheiden, ob ein Treffer wirklich das von Ihnen gemeinte Konzept ist. `case_sensitive: true` sorgt `API` für die Übereinstimmung ohneMATCHEN von "api" in Text.

## Übersetzen Sie sie in der Datei jeder Sprache

Erstellen oder öffnen Sie `L10N/<locale>.md` neben Ihrem `L10N.md` und ordnen Sie den Begriff mit der genehmigten Übersetzung zu:

```yaml
# L10N/es.md
---
locale: es
glossary:
  commit: commit
  API: API
---
```

```yaml
# L10N/ja.md
---
locale: ja
glossary:
  commit: コミット
  API: API
---
```

Schlüssel sind der `source`. Eine Sprache ohne Übersetzung für einen Begriff greift auf das Kontoglossar zurück oder lässt das Modell wählen.

## Fügen Sie einen Begriff hinzu, der nur von einer Sprache benötigt wird

Eine Sprachdatei kann ein Wort übersetzen, das `L10N.md` nicht kündigt. Die Regel gilt dann nur für diese Sprache:

```yaml
# L10N/es.md
---
locale: es
glossary:
  commit: commit
  pull request: pull request
---
```

## Verleihen Sie einem Begriff eine stabile ID

Wenn dasselbe Wort eine genaue Bedeutung benötigt, oder Sie den Quellbegriff `source` später umbenennen möchten, weisen Sie ihm eine `id` zu und binden Sie deren Übersetzungen an diese ID:

```yaml
# L10N.md
glossary:
  - id: vcs-branch
    source: branch
    definition: A line of development in version control, not a company branch office.
```

```yaml
# L10N/es.md
glossary:
  vcs-branch: rama
```

## Verfeinern Sie das Glossar für einen Teil des Repositories

Ein verschachtelt `L10N.md` oder `L10N/<locale>.md` erbt von seinen übergeordneten Verzeichnissen und kann Einträge für seinen Unterbaum hinzufügen oder überschreiben:

```yaml
# marketing/L10N/es.md
---
locale: es
glossary:
  commit: compromiso
---
```

Spanische Dateien unter `marketing/` übersetzen "commit" als `compromiso`; der Rest des Repositories behält `commit`.

## Commit und Push

Committen Sie die Änderung und drücken Sie. Im nächsten Übersetzungsdurchlauf übersetzt Glossia neu nur die Dateien, die die von Ihnen hinzugefügten oder geänderten Begriffe verwenden, in den Sprachen, deren Übersetzungen geändert wurden. Dateien, die diese Begriffe nicht enthalten, behalten ihre bestehenden Übersetzungen.

Wenn ein Glossar einen Fehler hat, ignoriert Glossia das Repositoriumglossar für die betroffenen Dateien und verwendet nur das Kontoglossar, sodass Sie die [Validierungsregeln](/docs/reference/glossary#validation) prüfen, wenn ein Begriff nicht zu passen scheint.

## Siehe Auch

- [Glossarreferenz](/docs/reference/glossary): jedes Feld und Validierungsregel.
- [Glossar](/docs/explanation/glossary): wie die Repositorium-und Kontoglossare kombinieren.
- [L10N.md Referenz](/docs/reference/l10n-md): die anderen Frontmatter Felder.