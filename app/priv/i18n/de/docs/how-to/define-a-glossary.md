%{
  title: "Ein Glossar definieren",
  summary:
    "Legen Sie Begriffe in L10N.md und deren genehmigte Übersetzungen in der Override-Datei jeder Sprache fest.",
  category: "Anleitung",
  section: "translation",
  order: 6
}
---

Ihr Team verfügt bereits über Begriffe, die auf eine bestimmte Weise übersetzt werden müssen: Produktnamen, die im Englischen verbleiben, technische Begriffe mit einer bevorzugten Darstellung und Markenwörter, die einen spezifischen Ton tragen. Definieren Sie diese in Ihrem Repository und Glossia wendet sie auf jede zukünftige Übersetzung an.

Ein Glossar befindet sich in zwei Arten von Dateien, die Sie bereits nutzen:

- `L10N.md` definiert die **Begriffe**: was das Wort ist und was es bedeutet. Dies gilt für jede Sprache.
- `L10N/<locale>.md` definiert die **Übersetzungen** für eine Sprache. Die Rezensenten jeder Sprache übernehmen ihre eigene Datei.

Falls Ihr Konto auch ein Glossar in Glossia enthält, werden die beiden zur Übersetzungszeit zusammengeführt. Für die Regeln und für [wann was verwendet wird](/docs/explanation/glossary#when-to-use-which) siehe [Glossar](/docs/explanation/glossary).

## 1. Definieren Sie die Begriffe in L10N.md

Fügen Sie eine `glossary`-Liste in die Frontmatter Ihrer Wurzeldatei `L10N.md` ein:

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

Jeder Begriff benötigt eine `source` [das Wort, so wie es in Ihrem Text erscheint]. Eine `definition` hilft dem Modell zu entscheiden, ob ein Treffer tatsächlich das von Ihnen gemeinte Konzept ist. `case_sensitive: true` stellt sicher, dass `API` passt, ohne dass "api" im Fließtext abgeglichen wird.

## 2. Übersetzen Sie sie in jede Sprachdatei

Erstellen oder öffnen Sie `L10N/<locale>.md` neben `L10N.md` und übertragen Sie jeden Begriff in seine genehmigte Übersetzung:

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

Schlüssel sind der `source` des Begriffs. Eine Sprache ohne Übersetzung für einen Begriff greift auf das Kontoglossar zurück oder lässt das Modell entscheiden.

## 3. Fügen Sie einen Begriff hinzu, der nur eine Sprache benötigt

Eine Sprachdatei kann ein Wort übersetzen, das `L10N.md` nicht deklariert. Dann gilt die Regel nur für diese Sprache:

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

Wenn dasselbe Wort eine präzise Bedeutung benötigt oder Sie später den `source` eines Begriffs umbenennen möchten, geben Sie ihm eine `id` und verknüpfen Sie seine Übersetzungen mit dieser ID:

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

## 5. Verfeinern Sie das Glossar für einen Teil des Repositories

Eingebettete `L10N.md` oder `L10N/<locale>.md` erben von ihren übergeordneten Verzeichnissen und können Einträge für ihren Unterbaum hinzufügen oder überschreiben:

```yaml
# marketing/L10N/es.md
---
locale: es
glossary:
  commit: compromiso
---
```

Spanische Dateien unter `marketing/` übersetzen "commit" als `compromiso`; der Rest des Repositories behält `commit` bei.

## 6. Commit und Push

Führen Sie den Commit und Pushen Sie die Änderung durch. Beim nächsten Übersetzungslauf übersetzt Glossia nur die Dateien neu, die die von Ihnen hinzugefügten oder geänderten Begriffe enthalten, und zwar nur in den Sprachen, deren Übersetzungen sich geändert haben. Dateien, die diese Begriffe nicht enthalten, behalten ihre bestehenden Übersetzungen.

Wenn ein Glossar einen Fehler enthält, ignoriert Glossia das Repository-Glossar für die betroffenen Dateien und verwendet lediglich das Kontoglossar; prüfen Sie also die [Validierungsregeln](/docs/reference/glossary#validation), wenn ein Begriff scheinbar nicht zutrifft.

## Siehe auch

- [Glossar-Referenz](/docs/reference/glossary): jedes Feld und jede Validierungsregel.
- [Glossar](/docs/explanation/glossary): wie die Repository- und Kontoglossare kombiniert werden.
- [L10N.md Referenz](/docs/reference/l10n-md): die anderen Frontmatter-Felder.
