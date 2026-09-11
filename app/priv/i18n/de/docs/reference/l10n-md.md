%{
  title: "L10N.md",
  summary: "Referenz für Repository-Übersetzungseinstellungen und Kontext.",
  category: "Referenz",
  order: 1
}
---
`L10N.md` teilt Glossia mit, welche Dateien übersetzt werden sollen, wohin die übersetzten Dateien gehören sollen, welche Sprachen als Ziel festgelegt werden sollen und welcher Kontext das Ergebnis leiten soll. Ein Repository kann eine Wurzeldatei und zusätzliche, bereichsbezogene Dateien in Unterordnern enthalten.

## Struktur

Jede Datei besteht aus zwei Teilen:

1. [YAML Ain't Markup Language](https://yaml.org/) Frontmatter zwischen `---` Markierungen.
2. Markdown unter dem Frontmatter mit Produkt-, Publikums-, Stimmm- oder Bereichskontext.

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

Anbieter-Credentials gehören in die Kontoeinstellungen, niemals in `L10N.md`. Der optionale `model`-Wert ist ein Account-Modell-Handle.

## Frontmatter-Felder

| Feld | Typ | Erforderlich | Beschreibung |
|---|---|---|---|
| `source_language` | Zeichenkette | nein | Quelldialekt für diesen Bereich. Standardmäßig `en`. |
| `model` | Zeichenkette | nein | Account-Modell-Handle. Glossia verwendet die Account-Standardauswahl, wenn offen, und meldet einen Fehler, wenn der explizite Handle nicht existiert. |
| `sources` | Abbildung oder Liste | für eine Regel auf oberster Ebene | Quellmustern. Abbildungswerte können Ausgabe-Vorlagen definieren. |
| `targets` | Abbildung oder Liste | wenn Quellen konfiguriert sind | Zielsprachencodes. Eine Abbildung kann einen Sprachcode mit einem Sprachnamen verbindend. |
| `output` | Zeichenkette | wenn keine Quellenabbildung oder `target_path` ein Ziel bereitstellt | Output-Datei-Vorlage. |
| `target_path` | Zeichenkette | wenn keine Quellenabbildung oder `output` ein Ziel bereitstellt | Basisverzeichniss-Vorlage für übersetzte Dateien. |
| `translate` | Liste | nein | Mehrere Übersetzungsregeln, jede mit eigenen Quellen und OPTIONALen Änderungen. |
| `exclude` | Liste | nein | Datei-Muster zum Überspringen. |
| `preserve` | Liste | nein | Inhaltstypen, die unverändert bleiben müssen, wie Platzhalter oder einheitliche Standort-Identifikatoren. |
| `frontmatter` | Zeichenkette | nein | `preserve` standardmäßig, oder `translate`. |
| `prompt` | Zeichenkette | nein | Zusätzliche Anleitung für diesen Bereich oder die Regel. |
| `validation` | Liste | für Dateierweiterungen ohne integrierten Adapter | Ein Validierungsbefehl gefolgt von seinen Argumenten. Der Befehl erhält den Kandidaten an seinem realen Zieltransparenz und muss einen nicht-null-Status zurückgeben, wenn die Datei ungültig ist. |
| `check_cmd` | Zeichenkette | nein | Ein Prüfbefehl, der dem Übersetzungsworkflow verfügbar ist. |
| `check_cmds` | Abbildung | nein | Benannte Prüfbefehle, die dem Übersetzungsworkflow verfügbar sind. |
| `retries` | Ganzzahl | nein | Anzahl der Wiederversuche nach einer fehlgeschlagenen Prüfung. Standardmäßig `2`. |
| `locale` | Zeichenkette | nein | An einen lokalitätsspezifischen Kontext-Datei angehängter Arbeitsumgebung. |

Unbekannte Frontmatter-Felder werden ignoriert.

## Dateiformate

Glossia hat integrierte Bearbeitung für Markdown, JavaScript Object Notation, YAML Ain't Markup Language, portable Object und Klartextdateien. Andere Dateierweiterungen führen zum Versagen bei der Planung, es sei denn, die einschlägige `L10N.md` deklariert einen `validation`-Befehl. Dies verhindert, dass proprietäre strukturierte Formate stillschweigend als unbeschränkter Text behandelt werden.

Der Validierungsbefehl läuft nach, nachdem der Kandidat temporär an seinen realen Zielpfad geschrieben wurde. Er kann den nativen Parser, Compiler oder Build-Befehl des Repositorys aufrufen. Glossia stellt das vorherige Ziel nach jedem Validierungsversuch wieder her und schreibt den akzeptierten Kandidaten erst danach.

## Quellenzuordnungen

Die klarste Form bildet jedes Quellmuster auf eine Ausgabe-Vorlage ab:

```yaml
sources:
  "docs/**/*.md": "docs/i18n/{locale}/{relpath}"
  "content/*.json": "content/{locale}/{basename}.{ext}"
```

Eine Quellenliste ist ebenfalls gültig, benötigt aber `output` oder `target_path`, um das Ziel zu definieren:

```yaml
sources:
  - "docs/**/*.md"
target_path: "docs/i18n/{locale}"
```

## Zielsprachen

Eine Liste verwendet jeden Lokalcod als Bezeichner für die Sprache:

```yaml
targets:
  - es
  - ja
```

Eine Zuordnung kann einen lesbaren Sprachnamen hinzufügen:

```yaml
targets:
  es: Spanish
  ja: Japanese
```

## Ausgabetabellenvariablen

| Variable | Wert |
|---|---|
| `{locale}` oder `{lang}` | Code für die Zellsprache (Lokale). |
| `{relpath}` | Quellpfad relativ zum passenden Muster. |
| `{basename}` | Quelldateiname ohne die Dateiendung. |
| `{ext}` | Dateiendung der Quelldatei ohne den führenden Punkt. |

## Mehrere Regeln

Verwenden Sie `translate`, wenn verschiedene Inhaltgruppen unterschiedliche Zielpfade oder Aussichten benötigen:

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

Regelwerte überschreiben Werte, die aus der umgebenden Datei geerbt wurden.

## Eingeschränkter Kontext

Glossia liest `L10N.md`-Dateien vom Repository-Wurzelverzeichnis hin zur Quelldatei:

- Einstellungen höherer Ordnern liefern Standardwerte.
- Eine tiefere Datei überschreibt Felder für ihr Verzeichnis.
- Der Markdown-Kontext wird von übergeordneten zu untergeordneten Dateien aufgebaut.
- Locale-spezifische Anweisungen und ein Locale-spezifischer Modell-Handler können in `L10N/<locale>.md` abgespeichert werden.

Dies ermöglicht es einem Repository, weite Sprachanweisungen am Wurzelverzeichnis zu halten, während produktbereich- oder sprachespezifische Anweisungen nah am betroffenen Inhalt platziert werden.