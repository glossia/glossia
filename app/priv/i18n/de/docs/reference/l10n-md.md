%{
  title: "L10N.md",
  summary: "Referenz für Repository-Übersetzungseinstellungen und Kontext.",
  category: "Referenz",
  section: "translation",
  order: 1
}
---

`L10N.md` definiert, welche Dateien zu übersetzen sind, wohin die Übersetzungen gehören, welche Sprachen als Ziel dienen und welcher Kontext das Ergebnis leiten soll. Ein Repository kann eine Root-Datei und weitere, in Unterordnern eingeschränkte Dateien enthalten.

## Struktur

Jede Datei besteht aus zwei Teilen:

1. [YAML Ain't Markup Language](https://yaml.org/) Frontmatter zwischen `---` Markierungen.
2. Markdown unterhalb des Frontmatter mit Produkt-, Zielgruppen-, Stil- oder Domänenkontext.

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

Anbieterzugangsdaten gehören in die Kontoeinstellungen, niemals in `L10N.md`. Der optionale `model`-Wert ist ein Konto-Modell-Handle.

## Frontmatter-Felder

| Feld | Typ | Erforderlich | Beschreibung |
|---|---|---|---|
| `source_language` | Zeichenkette | nein | Quell-Locale für diesen Bereich. Der Standardwert ist `en`. |
| `model` | Zeichenkette | nein | Konto-Modell-Handle. Glossia verwendet den Standardwert des Kontos, wenn dieser weggelassen wird, und meldet einen Fehler, wenn ein expliziter Handle nicht existiert. |
| `sources` | Mappe oder Liste | für eine Top-Level-Regel | Quelldatei-Patterns. Map-Werte können Ausgabe-Vorlagen definieren. |
| `targets` | Mappe oder Liste | wenn Quellen konfiguriert sind | Ziel-Locale-Codes. Eine Mappe kann einen Locale-Code mit einem Sprachnamen zuordnen. |
| `output` | Zeichenkette | wenn keine Quell-Mapping verfügbar ist oder `target_path` ein Ziel bereitstellt | Ausgabe-Datei-Vorlage. |
| `target_path` | Zeichenkette | wenn keine Quell-Mapping verfügbar ist oder `output` ein Ziel bereitstellt | Vorlagetempel für Übersetzungsdateien im Basisverzeichnis. |
| `translate` | Liste | nein | Mehrfache Übersetzungsregeln, jede mit eigenen Quellen und optionalen Überschreibungen. |
| `exclude` | Liste | nein | Dateimuster, die übersprungen werden sollen. |
| `preserve` | Liste | nein | Inhaltstypen, die unverändert bleiben müssen, wie Platzhalter oder URLs. |
| `frontmatter` | Zeichenkette | nein | `preserve` standardmäßig, oder `translate`. |
| `prompt` | Zeichenkette | nein | Zusätzliche Anleitung für diesen Bereich oder Regel. |
| `validation` | Liste | für Datei-Endungen ohne eingebauten Adapter | Ein Validierungsbefehl gefolgt von seinen Argumenten. Der Befehl empfängt den Kandidaten an seinem realen Ziel-Pfad und muss bei ungültiger Datei einen Status ungleich Null zurückgeben. |
| `check_cmd` | Zeichenkette | nein | Ein Überprüfungs-Befehl, der dem Übersetzungs-Workflow zur Verfügung steht. |
| `check_cmds` | Mappe | nein | Benannte Überprüfungs-Befehle, die dem Übersetzungs-Workflow zur Verfügung stehen. |
| `retries` | Ganzzahl | nein | Anzahl der Wiederversuche nach einer fehlgeschlagenen Überprüfung. Standardmäßig `2`. |
| `locale` | Zeichenkette | nein | Locale, die an eine lokal-spezifische Kontext-Datei angehängt ist. |
| `glossary` | Liste oder Mappe | nein | In `L10N.md` eine Liste von Glossar-Begriffen. In `L10N/<locale>.md` eine Mappe von jedem Begriff zu dessen Übersetzung in dieser Sprache. Geschachtelte Dateien erweitern und überschreiben die vererbten Einträge. Siehe die [Glossarreferenz](/docs/reference/glossary). |

Unbekannte Frontmatter-Felder werden ignoriert.

## Dateiformate

Glossia bietet integrierte Verarbeitung für Markdown, JavaScript Object Notation, YAML Ain't Markup Language, portables Objekte und Textdateien. Andere Dateiendungen scheitern bei der Planung, es sei denn, die anwendbare `L10N.md` deklariert einen `validation`-Befehl. So wird verhindert, dass ein proprietäres Format stumm als unbeschränkter Text behandelt wird.

In Markdown wird nur Prosa übersetzt: Absätze, Überschriften, Listeneinträge, Tabellenzellen, die `title`-, `details`-, `alt`-, `label`-, `description`-, `summary`-, `placeholder`-, `aria-label`- und `caption`-Attribute von Komponenten und HTML, sowie der Text einesHTML `<summary>`-Elements. Jedes andere Byte, einschließlich Code, Link-Ziele, Komponenten, Warnmeldungen und explizite Überschriften-Anker, wird genau wie in der Quelle beibehalten. Für die Funktionsweise siehe [Übersetzungswiederherstellung](/docs/explanation/translation-recovery).

Der Validierungsbefehl wird ausgeführt, nachdem der Kandidat vorübergehend an seinen realen Ziel-Pfad geschrieben wurde. Er kann den nativen Parser, Compiler oder Build-Befehl des Repositories aufrufen. Glossia stellt das vorherige Ziel nach jeder Validierungsversuch wieder her und schreibt nur den akzeptierten Kandidaten danach.

## Quell-Mapping

Die klarste Form ordnet jedes Quellmuster einem Ausgabe-Vorlage zu:

```yaml
sources:
  "docs/**/*.md": "docs/i18n/{locale}/{relpath}"
  "content/*.json": "content/{locale}/{basename}.{ext}"
```

Eine Quellenliste ist auch gültig, benötigt aber `output` oder `target_path` um das Ziel zu definieren:

```yaml
sources:
  - "docs/**/*.md"
target_path: "docs/i18n/{locale}"
```

## Zielsprachen

Eine Liste verwendet jeweils den Locale-Code als Sprach-Identifier:

```yaml
targets:
  - es
  - ja
```

Eine Mappe kann einen lesbaren Sprachnamen hinzufügen:

```yaml
targets:
  es: Spanish
  ja: Japanese
```

## Ausgabeevariablen

| Variable | Wert |
|---|---|
| `{locale}` oder `{lang}` | Ziel-Locale-Code. |
| `{relpath}` | Quell-Pfad relativ zum übereinstimmenden Muster. |
| `{basename}` | Quell-Dateiname ohne seine Erweiterung. |
| `{ext}` | Quell-Dateiendung ohne den führenden Punkt. |

## Mehrere Regeln

Verwenden Sie `translate` wenn unterschiedliche Inhaltsgruppen verschiedene Ziele oder Prüfungen benötigen:

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

## Kontext mit Geltungsbereich

Glossia liest `L10N.md`-Dateien vom Repository-Root in Richtung der Quelldatei:

- Elterneinstellungen liefern Standardwerte.
- Eine tiefere Datei überschreibt Felder für ihr Verzeichnis.
- Der Markdown-Kontext wird von übergeordneten zu untergeordneten Ebenen akkumuliert.
- Lokalspezifische Hinweise und ein lokalspezifisches Modell-Handle können in `L10N/<locale>.md` liegen.

Dies ermöglicht es einem Repository, breite Stimmenführung am Root zu behalten, während produktbereichs- oder sprachspezifische Hinweise nah am von ihnen betroffenen Inhalt platziert werden.
