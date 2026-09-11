%{
  title: "L10N.md",
  summary: "Referenz für Repository-Übersetzungseinstellungen und Kontext.",
  category: "Referenz",
  order: 1
}
---
`L10N.md` gibt Glossia an, welche Dateien zu übersetzen sind, wohin die übersetzten Dateien gehören, welche Sprachen als Ziel anzustreben sind und welcher Kontext das Ergebnis leiten soll. Ein Repository kann eine Wurzel datei und zusätzliche datenbereichsbezogene Dateien in Unterordnern enthalten.

## Struktur

Jede Datei hat zwei Teile:

1. [YAML Ain't Markup Language](https://yaml.org/) -Vordergründe zwischen `---` Markierungen.
2. Markdown unter dem Vordergrund mit Produkt-, Zielpublikums-, Ton- oder Domänenkontext.

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

Anbieterzugangsdaten gehören in die Kontoeinstellungen, niemals in `L10N.md`. Der optionale `model`-Wert ist ein Kontomodell-Handle.

## Frontmatter-Felder

| Feld | Typ | Erforderlich | Beschreibung |
|---|---|---|---|
| `source_language` | string | nein | Herkunftssprache für diesen Geltungsbereich. Standardwert `en`. |
| `model` | string | nein | Kontomodell-Handle. Glossia verwendet den kontobeladenen Standardwert, wenn nichts festgelegt ist, und meldet einen Fehler, wenn ein expliziter Handle nicht existiert. |
| `sources` | map or list | für eine Top-Level-Regel | Quelldateimuster. Map-Werte können Ausgabevorlagen definieren. |
| `targets` | map or list | wenn Quellen konfiguriert sind | Zielzwischenreichencodes. Eine Map kann einen Sprachcode mit einem Sprachnamen verknüpfen. |
| `output` | string | wenn keine Quellmapping oder `target_path` ein Ziel liefern | Ausgabetemplate. |
| `target_path` | string | wenn keine Quellmapping oder `output` ein Ziel liefern | Basis-Verzeichnisvorlage für übersetzte Dateien. |
| `translate` | list | nein | Mehrere Übersetzungsregeln, jede mit eigenen Quellen und Optionen überdeckb. |
| `exclude` | list | nein | Dateimuster aus, die übersprungen werden. |
| `preserve` | list | nein | Inhaltarten, die unverändert bleiben müssen, wie Platzhalter oder URIs. |
| `frontmatter` | string | nein | `preserve` oder `translate` implizit. |
| `prompt` | string | nein | Zusätzliche Anweisungen für diesen Geltungsbereich oder Regel. |
| `validation` | list | für Dateiendungen ohne eingebaute Adapter | Ein Validierungsbefehl gefolgt von seinen Argumenten. Der Befehl erhält den Kandidaten auf seinem echten Zielpfad und muss bei ungültiger Datei einen nichtnullen Status zurückgeben. |
| `check_cmd` | string | nein | Ein Prüfungsbefehl verfügbar für das Übersetzungswerk. |
| `check_cmds` | map | nein | Benannte Prüfungsbefehle verfügbar für das Übersetzungswerk. |
| `retries` | integer | nein | Anzahl Wiederholungsversuche nach einer gescheiterten Prüfung. Standardwert ist `2`. |
| `locale` | string | nein | Zwischenreich, das einem örtsspezifischen Kontextdatei angehängt ist. |

Unbekannte Frontmatter-Felder werden ignoriert.

## Dateiformate

Glossia hat native Unterstützung für Markdown, JavaScript Object Notation, YAML Ain't Markup Language, portable object und Textdateien. Andere Dateiendungen scheitern die Planung, es sei denn, die einschlägige `L10N.md` deklariert einen `validation`-Befehl. Dies verhindert, dass eine proprietäre strukturierte Datei stumm als unbeschränkter Text behandelt wird.

Der Validierungsbefehl läuft nach dem Kandidaten nach dem Schreiben vorübergehend auf seinen echten Zielpfad. Er kann den nativen Parser, den Compiler oder den Build-Befehl des Respositories aufrufen. Glossia stellt nach jedem Validierungsversuch den vorherigen Zielverlauf wieder her und schreibt den akzeptierten Kandidaten erst danach.

## Quellenzuordnungen

Die klarste Form ordnet jedem Quellmuster ein Ausgabeziel zu:

```yaml
sources:
  "docs/**/*.md": "docs/i18n/{locale}/{relpath}"
  "content/*.json": "content/{locale}/{basename}.{ext}"
```

Eine Quellliste ist ebenfalls gültig, benötigt aber `output` oder `target_path`, um das Ziel zu definieren:

```yaml
sources:
  - "docs/**/*.md"
target_path: "docs/i18n/{locale}"
```

## Zielsprachen

Eine Liste verwendet den Locale-Code jedes Eintrags als Sprach-Identifier:

```yaml
targets:
  - es
  - ja
```

Eine Zuordnung kann einen lesbaren Sprache-Namen hinzufügen:

```yaml
targets:
  es: Spanish
  ja: Japanese
```

## Ausgabevariablen

| Variable | Wert |
|---|---|
| `{locale}` oder `{lang}` | Sprichcode der Zielsprache. |
| `{relpath}` | Quellpfad relativ zum übereinstimmenden Muster. |
| `{basename}` | Quelldateiname ohne seine Erweiterung. |
| `{ext}` | Quelldateinerweiterung ohne das führende Punktzeichen. |

## Mehrfache Regeln

Verwenden Sie `translate`, wenn verschiedene Inhaltgruppen unterschiedliche Ziele oder Prüfungen benötigen:

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

Werte der Regeln überschreiben Werte, die aus der umgebenden Datei vererbt werden.

## Kontextbereich

Glossia liest `L10N.md`-Dateien vom Repository-Wurzelverzeichnis bis zur Quelldatei:

- Einstellungen im übergeordneten Verzeichnis liefern Standardwerte.
- Tiefere Dateien überschreiben Felder für ihr Verzeichnis.
- Der Markdown-Kontext wird von Eltern über Kinder akkumuliert.
- Locale-spezifische Orientierungen und ein für diese Locale spezifisches Modell-Handle können in `L10N/<locale>.md` leben.

Dies ermöglicht es einem Repository, umfassende Sprachführung am Root zu belassen, während produktbereichs- oder sprachespezifische Anleitung in der Nähe des Inhalts platziert wird, den es betrifft.