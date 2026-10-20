%{
  title: "Ein Glossar definieren",
  summary:
    "Definiere Begriffe in L10N.md und ihre genehmigten Übersetzungen in der Überschreibungsdatei jeder Sprache.",
  category: "Anleitung",
  section: "translation",
  order: 6
}
---

Ihr Team verfügt bereits über Begriffe, die auf eine bestimmte Weise übersetzt werden müssen: Produktnamen, die im Englischen bleiben, technische Begriffe mit einer bevorzugten Darstellung und Markenwörter, die eine bestimmte Nuance tragen. Nennt sie in eurem Repository und Glossia wendet sie auf jede zukünftige Übersetzung an.

Ein Glossar lebt in zwei Arten von Dateien, die ihr bereits verwendet:

- `L10N.md` definiert die **Begriffe**: was das Wort ist und was es bedeutet. Das gilt für jede Sprache gleichermaßen.
- `L10N/<locale>.md` definiert die **Übersetzungen** für eine Sprache. Die Rezensenten jeder Sprache betreuen ihre eigene Datei.

Wenn Ihr Konto zudem ein Glossar in Glossia hat, werden die beiden zum Übersetzungszeitpunkt verschmolzen. Siehe [Glossar](/docs/explanation/glossary) für die Regeln und für [wann Sie welchen verwenden](/docs/explanation/glossary#when-to-use-which).

## 1. Deklarieren Sie die Begriffe in L10N.md

Fügen Sie eine `glossary`-Liste in den Frontmatter des Wurzeldateiheaders `L10N.md` hinzu:

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

Jeder Begriff benötigt ein `source`, das Wort wie es in Ihrem Text erscheint. Eine `definition` hilft dem Modell zu entscheiden, ob ein Treffer wirklich das gemeinte Konzept ist. `case_sensitive: true` sorgt dafür, dass `API` übereinstimmt, ohne dass „api" im Text übereinstimmt.

## 2. Übersetzen Sie sie in der Datei jeder Sprache

Erstellen oder öffnen Sie `L10N/<locale>.md` neben Ihrem `L10N.md` und weisen Sie jeden Begriff auf seine genehmigte Übersetzung zu:

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

Die Schlüssel sind die `source` des Begriffs. Wenn eine Sprache keine Übersetzung für einen Begriff hat, fällt sie auf das Kontoglossar zurück oder lässt das Modell die Entscheidung treffen.

## 3. Fügen Sie einen Begriff hinzu, der nur von einer Sprache benötigt wird

Eine Sprachdatei kann ein Übersetzung für ein Wort bereitstellen, das `L10N.md` nicht deklariert. Die Regel gilt dann erst für diese Sprache allein:

```yaml
# L10N/es.md
---
locale: es
glossary:
  commit: commit
  pull request: pull request
---
```

## 4. Geben Sie einem Begriff eine stabile ID

Wenn das gleiche Wort eine präzise Bedeutung benötigt, oder Sie später den `source` eines Begriffs umbenennen möchten, geben Sie ihm eine `id` und verweisen Sie Übersetzungen über diese ID:

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

## 5. Verfeinern Sie das Glossar für einen Teil des Repository

Ein verschachteltes `L10N.md` oder `L10N/<locale>.md` leitet sich von den übergeordneten Verzeichnissen ab und kann Einträge für den Unterbaum hinzufügen oder überschreiben:

```yaml
# marketing/L10N/es.md
---
locale: es
glossary:
  commit: compromiso
---
```

Spanische Dateien unter `marketing/` übersetzen „commit" als `compromiso`; der Rest des Repository behält `commit`.

## 6. Commit und Push

Erstellen Sie den Commit und pushen Sie. Bei der nächsten Übersetzungsrunde übersetzt Glossia nur die Dateien neu, die die Begriffe verwenden, die Sie hinzugefügt oder geändert haben, in den Sprachen, deren Übersetzungen sich geändert haben. Dateien, die diese Begriffe nicht enthalten, behalten ihre bestehenden Übersetzungen.

Wenn ein Glossar einen Fehler enthält, ignoriert Glossia das Repository-Glossar für die betroffenen Dateien und verwendet nur das Kontoglossar, so dass Sie die [Validierungsregeln](/docs/reference/glossary#validation) prüfen, wenn ein Begriff scheinbar nicht anwendbar ist.

## Siehe auch

- [Glossar-Referenz](/docs/reference/glossary): jedes Feld und Validierungsregel.
- [Glossar](/docs/explanation/glossary): wie das Repository- und Kontoglossar kombiniert werden.
- [L10N.md Referenz](/docs/reference/l10n-md): die anderen Frontmatter-Felder.
