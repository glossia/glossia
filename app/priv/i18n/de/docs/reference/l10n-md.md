%{
  title: "L10N.md",
  summary: "Referenz für Repository-Übersetzungseinstellungen und Kontext.",
  category: "Referenz",
  order: 1
}
---
`L10N.md` erklärt Glossia, welche Dateien zu übersetzen sind, wohin die übersetzten Dateien gehören, welche Sprachen Ziel sind, und welcher Kontext das Ergebnis leiten soll. Ein Repository kann eine Root-Datei und zusätzliche in Unterordnern skopierte Dateien enthalten.

## Struktur

Jede Datei hat zwei Teile:

1. [YAML Ain't Markup Language](https://yaml.org/) Frontmatter zwischen `---`-Markierungen.
2. Markdown unterhalb des Frontmatter mit Produkt-, Zielgruppen-, Ton- oder Domänen-Kontext.

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

Provider-Zugangsdaten gehören in die Kontoeinstellungen, niemals in `L10N.md`. Der optionale `model`-Wert ist ein Handle des Kontomodells.

## Frontmatter-Felder

| Feld | Typ | Erforderlich | Beschreibung |
|---|---|---|---|
| `source_language` | String | nein | Quell-Sprachkennung für diesen Bereich. Wird standardmäßig auf `en` zurückgesetzt. |
| `model` | String | nein | Handle des Kontomodells. Glossia nutzt das Standardkonto-Modell des Kontos, wenn weggelassen, und meldet einen Fehler, wenn ein expliziter Handle nicht existiert. |
| `sources` | Map oder Liste | für eine Top-Level-Regel | Quell-Datei-Patterns. Map-Werte können Ausgabe-Vorlagen definieren. |
| `targets` | Map oder Liste | wenn Quellen konfiguriert sind | Zielsprache-Codes. Eine Map kann einen Sprachkencode mit einem Sprachnamen assoziieren. |
| `output` | String | wenn keine Quellen-Mapping oder `target_path` ein Ziel bereitstellt | Ausgabedatei-Vorlage. |
| `target_path` | String | wenn keine Quellen-Mapping oder `output` ein Ziel bereitstellt | Basisverzeichnis-Vorlage für übersetzte Dateien. |
| `translate` | Liste | nein | Mehrere Übersetzungs-Regeln, jede mit eigenen Quellen und optionalen Überschreibungen. |
| `exclude` | Liste | nein | Datei-Patterns zum Überspringen. |
| `preserve` | Liste | nein | Inhaltstypen, die unverändert bleiben müssen, wie Platzhalter oder Uniforme Ressourcenzuordner. |
| `frontmatter` | String | nein | `preserve` standardmäßig, oder `translate`. |
| `prompt` | String | nein | Zusätzliche Anleitung für diesen Bereich oder Regel. |
| `validation` | Liste | für Dateierweiterungen ohne integrierten Adapter | Ein Validierungsbefehl gefolgt von seinen Argumenten. Der Befehl empfängt den Kandidaten am echten Ziel-Pfad und muss einen nicht-null Status zurückgeben, wenn die Datei ungültig ist. |
| `check_cmd` | String | nein | Ein Prüfbefehl, dem der Übersetzungs-Ablauf Zugriff gewährt. |
| `check_cmds` | Map | nein | Benannte Prüfbefehle, die dem Übersetzungs-Ablauf zur Verfügung stehen. |
| `retries` | Integer | nein | Anzahl der Wiederholungsversuche nach fehlgeschlagenem Check. Standardmäßig `2`. |
| `locale` | String | nein | Lokalität, die an eine lokalitätsspezifische Kontext-Datei angehängt ist. |

Unbekannte Frontmatter-Felder werden ignoriert.

## Dateiformate

Glossia verfügt über eingebaute Verarbeitung für Markdown, JavaScript Object Notation, YAML Ain't Markup Language, portable Objekte und reine Textdateien. Andere Dateierweiterungen versagen in der Planung, es sei denn, die entsprechende `L10N.md` deklariert einen `validation`-Befehl. Dies verhindert das stumme Behandeln einer proprietären strukturierten Darstellung als unkontrollierbaren Text.

Der Validierungsbefehler läuft nach dem vorübergehenden Schreiben des Kandidaten an dessen echtem Ziel-Pfad. Er kann den nativen Parser, Compiler oder Build-Befehl des Repositories aufrufen. Glossia stellt den vorherigen Zielstandort nach jedem Validierungsversuch wieder her und schreibt den angenommenen Kandidaten nur nachfolgend.

## Quellzuordnungen

Die klarste Form ordnet jedes Quell-Pattern einem Ausgabe-Vorlage zu:

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

## Zielsprachen

Eine Liste verwendet jeden Locale-Code als Sprachkürzel:

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
| `{locale}` oder `{lang}` | Code für das Zielsprachen-locale. |
| `{relpath}` | Pfad zur Quelldatei relativ zum passenden Muster. |
| `{basename}` | Dateiname der Quelldatei ohne Erweiterung. |
| `{ext}` | Dateinamerweiterung der Quelldatei ohnenden Punkt. |

## Mehrere Regeln

Verwenden Sie `translate`, wenn unterschiedliche Inhaltsgruppen verschiedene Zieldestinationen oder Prüfungen benötigen:

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

Regelwerte überschreiben Werte, die von der umgebenden Datei vererbt werden.

## Bereichskontext

Glossia liest `L10N.md`-Dateien vom Repository-Wurzelverzeichnis aus zur Quelldatei hin ein:

- Einstellungen der übergeordneten Ebene liefern Standards.
- Eine tiefere Datei überschreibt Felder für ihr Verzeichnis.
- Der Markdown-Kontext wird von der übergeordneten zur darunterliegenden Datei akkumuliert.
- Sprachspezifische Anleitungen und ein sprachspezifisches Modell-Handle können in `L10N/<locale>.md` vorhanden sein.

Dies ermöglicht es einem Repository, umfassende Tonfallrichtlinien am Wurzelverzeichnis zu belassen, während spezifische Anweisungen für Produktbereiche oder Sprachen in der Nähe des betroffenen Inhalts platziert werden.