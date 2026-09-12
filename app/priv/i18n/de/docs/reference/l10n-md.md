%{
  title: "L10N.md",
  summary: "Referenz für Repository-Übersetzungseinstellungen und Kontext.",
  category: "Referenz",
  order: 1
}
---
`L10N.md` definiert für Glossia, welche Dateien zu übersetzen sind, wohin die übersetzten Dateien gehören, welche Sprachen als Ziel gesetzt werden sollen und welcher Kontext das Ergebnis leiten soll. Ein Repository kann eine Root-Datei und weitere scoped Dateien in Unterordnern haben.

## Struktur

Jede Datei besteht aus zwei Teilen:

1. [YAML Ain't Markup Language](https://yaml.org/) Frontmatter zwischen `---` Markern.
2. Markdown nach dem Frontmatter mit Produkt-, Zielgruppen-, Sprach- oder Bereichskontext.

<!-- end list -->

```yaml
---
source_language: en
model: translation-default
sources:
  "docs/**/*.md": "docs/i18n/{locale}/{relpath}"
targets:
  - es
  - ja
validation:
  - ./scripts/validate-docs.sh
  - --strict
frontmatter: preserve
preserve:
  - placeholders
  - urls
---

Write for software developers. Keep product names and code samples unchanged.
```

Provider-Credentials gehören in die Kontoeinstellungen, niemals in `L10N.md`. Der optionale `model` Wert ist ein Kontokenvollständiger Handle.

## Frontmatter-Felder

| Feld | Typ | Erforderlich | Beschreibung |
|---|---|---|---|
| `source_language` | string | nein | Quellformat für diesen Geltungsbereich. Standardmäßig `en`.|
| `model` | string | nein | Kontokenvollständiger Handle. Glossia verwendet den Konteenstandard, wenn dieser nicht spezifiziert wird, und meldet einen Fehler, wenn ein expliziter Handle nicht existiert. |
| `sources` | map oder Liste | für eine Top-Level-Regel | Quelldatei-Muster. Map-Werte können Ausgabevorlagen definieren. |
| `targets` | map oder Liste | wenn Quellen konfiguriert sind | Zielsprachen-Code. Eine Map kann einen Sprachcode mit einem Sprachnamen verbinden. |
| `output` | string | wenn keine Quellzuordnung oder `target_path` ein Ziel angibt | Ausgabe-Dateivorlage. |
| `target_path` | string | wenn keine Quellzuordnung oder `output` ein Ziel angibt | Basisverzeichnissvorlage für übersetzte Dateien. |
| `translate` | Liste | nein | Mehrere Übersetzungsregeln, jede mit ihren eigenen Quellen und optionalen Überlagerungen. |
| `exclude` | Liste | nein | Dateimuster, die übersprungen werden sollen. |
| `preserve` | Liste | nein | Inhalt, der unverändert bleiben muss, wie Platzhalter oder uniforme Ressourcenlokatoren. |
| `frontmatter` | string | nein | `preserve` standardmäßig, oder `translate`.|
| `prompt` | string | nein | Zusätzliche Hinweisungen für diesen Geltungsbereich oder diese Regel. |
| `validation` | Liste | für Dateinamenerweiterungen ohne eingebauten Adapter | Ein Validierungsbefehl gefolgt von seinen Argumenten. Der Befehl erhält den Kandidaten an seinem echten Zielverzeichnissweg und muss einen nicht-null Status zurückgeben, wenn die Datei ungültig ist. |
| `check_cmd` | string | nein | Ein Prüf-Befehl, der im Übersetzungsworkflow verfügbar ist. |
| `check_cmds` | map | nein | Benannte Prüf-Befehle, die im Übersetzungsworkflow verfügbar sind. |
| `retries` | Ganzzahl | nein | Anzahl der Wiederversuchungsversuche nach einem fehlgeschlagenen Check. Standardmäßig `2`.|
| `locale` | string | nein | Format, das einer formatabhängigen Kontextdatei beiliegt. |

Unbekannte Frontmatter-Felder werden ignoriert.

## Dateiformate

Glossia hat einen eigenen Handler für Markdown, JavaScript Object Notation, YAML Ain't Markup Language, portable object und Text-Dateien. Andere Dateinamenerweiterungen planen außerhalb üblichen Ablaufs, es sei denn, das eigenständige `L10N.md` deklariert ein `validation` Befehl. Dies vermeidet einen stillen Umgang einer eigenständigenStructured-Format als unbeschränkten Text.

Der Validierungsbefehl läuft, nachdem der Kandidat vorübergehend seinem echten Zielverzeichnissweg geschrieben wurde. Er kann den natürlichen Parser, Compiler oder Build-Befehl des Repositories aufrufen. Glossia stellt die vorherige Zielseite nach jedem Validierungsversuch wieder her und schreibt nur den akzeptierten Kandidaten danach.

## Quellzuordnungen

Die klarste Form ordnet jedes Quellmuster einer Ausgabe-Vorlage zu:

```yaml
sources:
  "docs/**/*.md": "docs/i18n/{locale}/{relpath}"
  "content/*.json": "content/{locale}/{basename}.{ext}"
```

Eine Quell-Liste ist ebenfalls gültig, benötigt aber `output` oder `target_path`, um das Ziel zu definieren:

```yaml
sources:
  - "docs/**/*.md"
target_path: "docs/i18n/{locale}"
```

## Zielssprachen

Eine Liste verwendet jeden Locale-Code als Sprachkennzeichen:

```yaml
targets:
  - es
  - ja
```

Eine Mapping-Struktur kann einen lesbaren Sprachnamen hinzufügen:

```yaml
targets:
  es: Spanish
  ja: Japanese
```

## Ausgabevariablen

| Variable | Wert |
|---|---|
| `{locale}` oder `{lang}` | Code der Zielsprache. |
| `{relpath}` | Quell-Pfad relativ zum abgeglichenen Muster. |
| `{basename}` | Quell-Dateiname ohne Erweiterung. |
| `{ext}` | Dateierweiterung ohne den führenden Punkt. |

## Mehrere Regeln

Verwenden Sie `translate`, wenn unterschiedliche Inhaltsgruppen verschiedene Ziele oder Prüfungen benötigen:

```yaml
---
source_language: en
targets:
  - es
translate:
  - sources:
      - "docs/**/*.md"
    output: "docs/i18n/{locale}/{relpath}"
  - source: "messages/*.json"
    output: "messages/{locale}/{basename}.{ext}"
---
```

Regelwerte überschreiben Werte, die vom umgebenden Dokument geerbt wurden.

## Begrenzter Kontext

Glossia liest `L10N.md`-Dateien von der Repository-Wurzel zur Quelldatei:

- Elterneinstellungen bieten Standardwerte.
- Eine tiefer liegende Datei überschreibt Felder für ihr Verzeichnis.
- Markdown-Kontext wird von Eltern zu Kind angesammelt.
- Sprachspezifische Anweisungen und ein sprachspezifisches Modell-Handle können in `L10N/<locale>.md` liegen.

Dies ermöglicht es einem Repository, weitreichende Stimmrichtlinien an der Wurzel zu halten, während produktbereichs- oder -sprachspezifische Anweisungen in die Nähe des Inhalts rückt, der sie betrifft.