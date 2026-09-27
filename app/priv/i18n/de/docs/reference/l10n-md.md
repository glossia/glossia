%{
  title: "L10N.md",
  summary: "Referenz für Repository-Übersetzungseinstellungen und Kontext.",
  category: "Referenz",
  section: "Übersetzung",
  order: 1
}
---
`L10N.md` sagt Glossia, welche Dateien zu übersetzen sind, wohin die übersetzten Dateien gehören, welche Sprachen als Ziel dienen sollen, und welchen Kontext das Ergebnis leiten soll. Ein Repository kann eine Wurzeldatei und weitere Dateien mit Bereichsdefinitionen in Unterordnern haben.

## Struktur

Jede Datei hat zwei Teile:

1. [YAML Ain't Markup Language](https://yaml.org/) Frontmatter zwischen `---` Markierungen.
2. Markdown unterhalb des Frontmatter mit Produkt-, Publikum-, Stimme- oder Domänenkontext.

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

Provider-Zugangsdaten gehören in die Kontoeinstellungen, niemals in `L10N.md`. Der optionale `model`-Wert ist ein Kontomodell-Handle.

## Frontmatter-Felder

| Feld | Typ | Erforderlich | Beschreibung |
|---|---|---|---|
| `source_language` | string | nein | Quellokal für diesen Bereich. Standardsmäßig `en`. |
| `model` | string | nein | Konto-Modell-Handle. Glossia verwendet das Konto-Standard, wenn weggelassen und meldet einen Fehler, wenn eine explizite Handle nicht existiert. |
| `sources` | map oder Liste | für eine Top-Level-Regel | Quell-Dateimuster. Map-Werte können Ausgabe-Vorlagen definieren. |
| `targets` | map oder Liste | wenn Quellen konfiguriert sind | Ziel-LOCALE-Codes. Eine Map kann einen LOCALE-Code mit einem Sprachnamen verknüpfen. |
| `output` | string | wenn keine Quellenabbildung oder `target_path` einen Bestimmungsort liefert | Ausgabe-Datei-Vorlage. |
| `target_path` | string | wenn keine Quellenabbildung oder `output` einen Bestimmungsort liefert | Basisverzeichnis-Vorlage für übersetzte Dateien. |
| `translate` | Liste | nein | Mehrere Übersetzungsregeln, jede mit eigenen Quellen und optionalen Überschreibungen. |
| `exclude` | Liste | nein | Dateimuster zum Überspringen. |
| `preserve` | Liste | nein | Inhaltstypen, die unverändert bleiben müssen, wie z. B. Platzhalter oder Uniform Resource Locators. |
| `frontmatter` | string | nein | `preserve` aus dem ersten Standard, oder `translate`. |
| `prompt` | string | nein | Zusätzliche Anleitung für diesen Bereich oder Regel. |
| `validation` | Liste | für Datei-Erweiterungen ohne integrierten Adapter | Validierungsbefehl gefolgt von dessen Argumenten. Der Befehl erhält den Kandidaten an seinem tatsächlichen Zielpfad und muss einen nicht-null Status zurückgeben, wenn die Datei ungültig ist. |
| `check_cmd` | string | nein | Ein Prüfbefehl, der für den Übersetzungsablauf verfügbar ist. |
| `check_cmds` | map | nein | Benannte Prüfbefehle, die für den Übersetzungsablauf verfügbar sind. |
| `retries` | Ganzzahl | nein | Anzahl Wiederholungsversuche nach fehlgeschlagenem Check. Standardsmäßig `2`. |
| `locale` | string | nein | Anpassung an LOCALE-spezifischen Kontext-Datei. |
| `glossary` | Liste oder Map | nein | In `L10N.md`, eine Liste von Glossarbegriffen. In `L10N/<locale>.md`, eine Map von jedem Begriff zu seiner Übersetzung in dieser Sprache. Verschiedene Dateien fügen und überschreiben die vererbten Einträge hinzu. Sehen Sie die [Glossar-Referenz](/docs/reference/glossary). |

Unbekannte Frontmatter-Felder werden ignoriert.

## Dateiformate

Glossia bietet integrierte Unterstützung für Markdown, JavaScript Object Notation, YAML Ain't Markup Language, Portable Object und pure Textdateien. Andere Dateierweiterungen versagen bei der Planung, es sei denn, die zutreffende `L10N.md` deklariert einen `validation`-Befehl. Dies verhindert, dass ein proprietäres Strukturformat fälschlicherweise als ungebundene Textzeichenkette behandelt wird.

Der Validierungsbefehl wird ausgeführt, nachdem der Kandidat provisorisch an seinen eigentlichen Zielpfad geschrieben wurde. Er kann den nativen Parser, Compiler oder Build-Befehl des Repositories aufrufen. Glossia stellt den vorherigen Zielstand nach jedem Validierungsversuch wieder her und schreibt nur den akzeptierten Kandidaten danach.

## Quellzuordnungen

Die klarste Form ordnet jedes Quellmuster einer Ausgabe-Vorlage zu:

```yaml
sources:
  "docs/**/*.md": "docs/i18n/{locale}/{relpath}"
  "content/*.json": "content/{locale}/{basename}.{ext}"
```

Eine Quelldatei-Liste ist ebenfalls gültig, benötigt aber`output` oder`target_path` um das Ziel zu definieren:

```yaml
sources:
  - "docs/**/*.md"
target_path: "docs/i18n/{locale}"
```

## Zielsprachen

Eine Liste verwendet jeden lokalen Code als Sprachkennung:

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

## Ausgabewerte

| Variable | Wert |
|---|---|
| `{locale}` oder `{lang}` | Ziel-Locale-Code. |
| `{relpath}` | Quellpfad relativ zum übereinstimmenden Muster. |
| `{basename}` | Dateiname der Quelle ohne Erweiterung. |
| `{ext}` | Dateierweiterung der Quelle ohne Vorlaufpunkt. |

## Mehrere Regeln

Verwenden Sie`translate` wenn verschiedene Inhaltskategorien verschiedene Ziele oder Prüfungen benötigen:

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

Regelwerte überschreiben von der umgebenden Datei geerbte Werte.

## Eingeschränkter Kontext

Glossia liest`L10N.md` Dateien vom Depot-Wurzelverzeichnis zum Quelldatei:

- Eltern-Einstellungen liefern Standards.
- Eine tiefere Datei überschreibt Felder für ihr Verzeichnis.
- Markdown-Kontext wird von Eltern zu Kindern angesammelt.
- Lokalspezifische Hinweise und eine lokalspezifische Modelldatei können in`L10N/<locale>.md`.

Dies ermöglicht es einem Datengesicht, weite Stimmrichtlinien an der Wurzel zu erhalten, während es produktspezifische oder sprachspezifische Anweisungen dem betroffenen Inhalt nahe platziert.