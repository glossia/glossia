%{
  title: "Ein Glossar definieren",
  summary:
    "Definieren Sie Begriffe in L10N.md und deren genehmigte Übersetzungen in der jeweiligen Sprach-Override-Datei.",
  category: "Anleitung",
  section: "translation",
  order: 6
}
---
Ihr Team verfügt bereits über Begriffe, die eine bestimmte Art der Übersetzung erfordern: Produktnamen, die auf Englisch bleiben, technische Begriffe mit einer bevorzugten Darstellung und Markenwörter, die eine bestimmte Tonlage tragen. Definieren Sie diese in Ihrem Repository und Glossia wendet sie auf jede zukünftige Übersetzung an.

Ein Glossar bezieht sich auf zwei Dateitypen, die Sie bereits verwenden:

- `L10N.md` erklärt die **Begriffe**: was das Wort ist und was es bedeutet. Dies gilt für jede Sprache übereinstimmend.
- `L10N/<locale>.md` erklärt die **Übersetzungen** für eine Sprache. Die Prüfer jeder Sprache verwalten ihre eigene Datei.

Wenn Ihr Konto in Glossia ebenfalls ein Glossar hat, werden die beiden zur Übersetzungszeit verschmolzen. Siehe [Glossar-Referenz](/docs/explanation/glossary) für die Regeln und für [Glossar-Referenz](/docs/explanation/glossary#when-to-use-which), wann welches verwendet wird.

## 1\. Definieren Sie die Begriffe in L10N.md

Fügen Sie dem Frontmatter Ihrer root `glossary` eine `L10N.md`-Liste hinzu:

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

Jeder Begriff benötigt eine `source`, das Wort, wie es in Ihrem Text erscheint. Eine `definition` hilft dem Modell zu entscheiden, ob ein Treffer wirklich das von Ihnen gemeinte Konzept ist. `case_sensitive: true` sorgt dafür, dass `API` ohne Übereinstimmung mit "api" in der Prosa übereinstimmt.

## 2\. Übersetzen Sie sie in jeder Sprachdatei

Erstellen oder öffnen Sie `L10N/<locale>.md` neben Ihrer `L10N.md` und legen Sie jeden Begriff auf seine genehmigte Übersetzung ab:

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

Schlüssel sind die `source` des Begriffs. Eine Sprache, die für einen Begriff keine Übersetzung hat, greift auf das Kontoglossar zurück oder lässt das Modell entscheiden.

## 3\. Fügen Sie einen Begriff hinzu, der nur eine Sprache benötigt

Eine Sprachdatei kann ein Wort übersetzen, das in `L10N.md` nicht deklariert ist. Dann gilt die Regel nur für diese Sprache:

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

Wenn dasselbe Wort präzise folgen muss oder Sie den `source` eines Begriffs später umbenennen möchten, geben Sie ihm eine `id` und wählen Sie seine Übersetzungen durch diese ID:

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

## 5\. Verfeinern Sie das Glossar für einen Teil des Repositories

Ein verschachteltes `L10N.md` oder `L10N/<locale>.md` leitet Eigenschaften von den übergeordneten Verzeichnissen ab und kann Einträge für seinen Unterbaum hinzufügen oder überschreiben:

```yaml
# marketing/L10N/es.md
---
locale: es
glossary:
  commit: compromiso
---
```

Spanisch-Dateien unter `marketing/` übersetzen "commit" als `compromiso`; der Rest des Repositories behält `commit`.

## 6\. Committed und Push

Commi" tten Sie die Änderung und pushen Sie. Im nächsten Durchlauf der Übersetzung übersetzt Glossia nur die Dateien, die die Begriffe verwenden, die Sie hinzugefügt oder geändert haben, in den Sprachen, deren Übersetzungen geändert wurden. Dateien, die diese Begriffe nicht enthalten, behalten ihre vorhandenen Übersetzungen.

Wenn das Glossar einen Fehler aufweist, ignoriert Glossia das Repository-Glossar für die betroffenen Dateien und verwendet nur das Kontoglossar, also überprüfen Sie die [Validierungsregeln](/docs/reference/glossary#validation), wenn ein Begriff nicht eindeutig anzuwenden scheint.

## Siehe auch

- [Glossary reference](/docs/reference/glossary): alle Felder und Validierungsregeln.
- [Glossary](/docs/explanation/glossary): wie sich das Repository- und Account-Glossar zusammensetzen.
- [L10N.md reference](/docs/reference/l10n-md): die anderen Frontmatter-Felder.