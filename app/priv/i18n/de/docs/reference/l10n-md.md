%{
  title: "L10N.md",
  summary: "Referenz für Repository-Übersetzungseinstellungen und Kontext.",
  category: "reference",
  order: 1
}
---
`L10N.md` Legt für Glossia fest, welche Dateien zu übersetzen sind, wohin die übersetzten Dateien gehören, welche Zielsprachen genutzt werden sollen und welcher Kontext die Ergebnisse leiten soll. Ein Repository kann eine Wurzeldatei und weitere, bereichsbezogene Dateien in Unterordnern enthalten.

## Struktur

Jede Datei besteht aus zwei Teilen:

1. [YAML Ain't Markup Language](https://yaml.org/) Frontmatter zwischen `---` Markern.
2. Markdown unter dem Frontmatter mit Produkt-, Zielgruppen-, Tonfall- oder Domänenkontext.

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

Provider-Zugangsdaten gehören in die Kontoeinstellungen, niemals in `L10N.md`. Das optionale `model` Der Wert ist ein Account-Modell-Handle.

## Frontmatter-Felder

| Feld | Typ | Erforderlich | Beschreibung |
|---|---|---|---|
| `source_language` | string | nein | Quelle in diesem Scope. Standard: `en`. |
| `model` | string | ohne | Account-Modell-Handle. Glossia verwendet den Account-Standard, wenn nicht angegeben, und meldet einen Fehler, wenn kein explizites Handle existiert. |
| `sources` | Map oder Liste | für eine Top-Level-Regel | Quelldatei-Muster. Map-Werte können Ausgabe-Vorlagen definieren. |
| `targets` | Map oder Liste | wenn Quellen konfiguriert sind | Ziellokale-Codes. Eine Map kann einen Lokalecode einem Sprachnamen zuordnen. |
| `output` | string | wenn keine Quellzuordnung oder `target_path` definiert ein Ziel | Vorlage für die Ausgabedatei. |
| `target_path` | string | wenn kein Quellmapping vorhanden ist oder `output` definiert ein Ziel | Vorlage für das Basisverzeichnis der übersetzten Dateien. |
| `translate` | list | Nein | Mehrere Übersetzungsregeln, jede mit eigenen Quellen und optionalen Überschreibungen. |
| `exclude` | list | Nein | Dateimuster zum Überspringen. |
| `preserve` | list | no | Inhaltstypen, die unverändert bleiben müssen, wie Platzhalter oder Uniform-Ressourcen-Adresse (URL). |
| `frontmatter` | string | no | `preserve` standardmäßig oder `translate`. |
| `prompt` | Zeichenkette | Nein | Zusätzliche Hinweise für diesen Bereich oder diese Regel. |
| `validation` | list | für Dateierweiterungen ohne integrierten Adapter | Ein Validierungsbefehl gefolgt von seinen Argumenten. Der Befehl empfängt den Kandidaten an seinem tatsächlichen Zielpfad und muss einen von Null verschiedenen Status zurückgeben, wenn die Datei ungültig ist. |
| `check_cmd` | string | no | Ein Prüfbefehl, der im Übersetzungsarbeitsablauf verfügbar ist. |
| `check_cmds` | map | no | Benannte Prüfbefehle, die im Übersetzungsarbeitsablauf verfügbar sind. |
| `retries` | integer | no | Anzahl der Wiederholungsversuche nach einem fehlgeschlagenen Prüfbefehl. Standardmäßig auf `2`. |
| `locale` | string | nein | An eine kontextspezifische Kontextdatei angehängtes Lokales. |

Unbekannte Frontmatter-Felder werden ignoriert.

## Dateiformate

Glossia bietet integrierte Unterstützung für Markdown, JavaScript Object Notation, YAML Ain't Markup Language, Portable Object und Textdateien. Andere Dateierweiterungen führen zu Planungsfehlern, es sei denn, das anwendbare `L10N.md` erklärt einen `validation` Befehl. Dies verhindert, dass ein proprietäres Strukturformat stillschweigend als unbeschränkter Text behandelt wird.

Der Validierungsbefehl wird ausgeführt, nachdem der Kandidat vorübergehend in den tatsächlichen Zielpfad geschrieben wurde. Er kann den nativen Parser, Compiler oder Build-Befehl des Repositories aufrufen. Glossia stellt nach jedem Validierungsversuch das vorherige Ziel wieder her und schreibt den akzeptierten Kandidaten erst danach.

## Quellzuordnungen

Die klarste Form ordnet jedes Quellmuster einem Ausgabetemplate zu:

```yaml
sources:
  "docs/**/*.md": "docs/i18n/{locale}/{relpath}"
  "content/*.json": "content/{locale}/{basename}.{ext}"
```

Eine Quellenliste ist ebenfalls gültig, aber sie benötigt `output` oder `target_path` um das Ziel zu definieren:

```yaml
sources:
  - "docs/**/*.md"
target_path: "docs/i18n/{locale}"
```

## Zielsprachen

Eine Liste verwendet jeden Sprachcode als deren Sprachkennzeichen:

```yaml
targets:
  - es
  - ja
```

Eine Abbildung kann einen lesbaren Sprachnamen hinzufügen:

```yaml
targets:
  es: Spanish
  ja: Japanese
```

## Ausgabevariablen

| Variablen | Werte |
|---|---|
| `{locale}` oder `{lang}` | Zielsprachencode. |
| `{relpath}` | Relativer Quelldateipfad zum übereinstimmenden Muster. |
| `{basename}` | Quelldateiname ohne Erweiterung. |
| `{ext}` | Quelldatei-Erweiterung ohne den führenden Punkt. |

## Mehrere Regeln

Verwenden Sie `translate`, wenn verschiedene Inhaltsgruppen unterschiedliche Ziele oder Prüfungen benötigen:

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

Regelwerte überschreiben vom umgebenden Dokument geerbte Werte.

## Begrenzter Kontext

Glossia liest `L10N.md`-Dateien vom Repository-Wurzelordner bis zur Quelldatei:

- Elterneinstellungen liefern Standardeinstellungen.
- Ein tieferes Dokument überschreibt Felder für sein Verzeichnis.
- Der Markdown-Kontext wird vom Elternelement bis zum Kind angehäuft.
- Sprachspezifische Anleitung und ein sprachspezifischer Modell-Handle können in `L10N/<locale>.md` untergebracht werden.

Dies ermöglicht einem Repository, in der Wurzel breite „Stimme-Leitlinien" zu belassen, während produktbereichsbezogene oder sprachspezifische Anleitung nah am von ihnen beeinflussten Inhalt platziert werden.