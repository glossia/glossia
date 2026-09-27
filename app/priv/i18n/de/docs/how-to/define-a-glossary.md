%{
  title: "Glossar definieren",
  summary:
    "Begriffe in L10N.md und ihre freigegebenen Übersetzungen in der Überschreibdatei jeder Sprache deklarieren.",
  category: "Anleitung",
  section: "Übersetzung",
  order: 6
}
---
Ihr Team hat bereits Begriffe, die auf eine bestimmte Weise übersetzt werden müssen: Produktnamen, die auf Englisch bleiben, technische Begriffe mit einer bevorzugten Darstellung, Markenworte, die eine bestimmte Nuance tragen. Definieren Sie diese in Ihrem Repositorium und Glossia wendet sie auf jede zukünftige Übersetzung an.

Ein Glossar befindet sich in zwei Arten von Dateien, die Sie bereits verwenden:

- `L10N.md` deklariert die **Begriffe**: was das Wort ist und was es bedeutet. Das ist für jede Sprache dasselbe.
- `L10N/<locale>.md` deklariert die **Übersetzungen** für eine Sprache. Die Prüfer jeder Sprache sind für ihre eigene Datei zuständig.

Wenn Ihr Konto auch ein Glossar auf dem Server hat, werden die beiden zur Übersetzungszeit verschmolzen. Siehe [Glossar](/docs/explanation/glossary) für die Regeln und für [wann welcher verwendet wird](/docs/explanation/glossary#when-to-use-which).

## 1\. Definieren Sie die Begriffe in L10N.md

Fügen Sie eine `glossary`-Liste zum Frontmatter der Wurzel `L10N.md` hinzu:

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

Jeder Begriff benötigt eine `source`, das Wort, wie es in Ihrem Text erscheint. Eine `definition` hilft dem Modell zu entscheiden, ob ein Treffer wirklich das von Ihnen gemeinte Konzept ist. `case_sensitive: true` sorgt dafür, dass `API` übereinstimmt, ohne dass "api" in Text übereinstimmt.

## 2\. Übersetzen Sie sie in der Datei jeder Sprache

Erstellen Sie oder öffnen Sie `L10N/<locale>.md` neben dem `L10N.md` und ordnen Sie bei jedem Begriff die genehmigte Übersetzung zu:

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

Schlüssel sind die `source` des Begriffs. Eine Sprache mit keiner Übersetzung für einen Begriff fällt auf das Server-Glossar zurück oder lässt das Modell die Wahl treffen.

## 3\. Fügen Sie einen Begriff hinzu, der nur eine Sprache benötigt

Eine Sprachdatei kann ein Wort übersetzen, das `L10N.md` nicht deklariert. Die Regel gilt dann nur für diese Sprache:

```yaml
# L10N/es.md
---
locale: es
glossary:
  commit: commit
  pull request: pull request
---
```

## 4\. Geben Sie einem Begriff eine stabile ID

Wenn dasselbe Wort eine präzise Bedeutung benötigt, oder Sie den `source` eines Begriffs im Laufe der Zeit umbenennen möchten, geben Sie ihm eine `id` und schlüpfeln Sie die Übersetzungen über diese ID:

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

## 5\. Verfeinern Sie das Glossar für einen Teil des Repositoriums

Ein verschachtetes `L10N.md` oder `L10N/<locale>.md` erbt von seinen übergeordneten Verzeichnissen und kann Einträge für seine Unterstruktur hinzufügen oder überschreiben:

```yaml
# marketing/L10N/es.md
---
locale: es
glossary:
  commit: compromiso
---
```

Spanische Dateien unter `marketing/` übersetzen "commit" als `compromiso`; der Rest des Repositoriums behält `commit`.

## 6\. Commit und push

Kommittieren Sie die Änderung und pushen Sie. Beim nächsten Übersetzungs-Lauf neuübersetzt Glossia nur die Dateien, die die Begriffe verwenden, die Sie hinzugefügt oder geändert haben, in den Sprachen, deren Übersetzungen geändert wurden. Dateien, die diese Begriffe nicht enthalten, behalten ihre bestehenden Übersetzungen.

Wenn ein Glossar einen Fehler hat, ignoriert Glossia das Repositorium-Glossar für die betroffender Dateien und verwendet nur das Server-Glossar, sodass Sie die [Validierungsregeln](/docs/reference/glossary#validation) prüfen, wenn ein Begriff nicht scheinbar anwendbar ist.

## Siehe auch

- [Glossar-Referenz](/docs/reference/glossary): jedes Feld und jede Validierungsregel.
- [Glossar](/docs/explanation/glossary): wie die Repositorium- und Server-Glossare kombiniert werden.
- [L10N.md-Referenz](/docs/reference/l10n-md): die anderen Frontmatter-Felder.