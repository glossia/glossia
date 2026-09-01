%{
  title: "GLOSSIA.md",
  summary: "Referenz für Repository-Übersetzungseinstellungen und Kontext.",
  category: "Referenz",
  order: 1
}
---
`GLOSSIA.md` gibt Glossia mit, welche Dateien übersetzt werden sollen, wohin übersetzte Dateien gehören, welche Sprachen zielsprache sind und welcher Kontext das Ergebnis leiten soll. Ein Repository kann eine WurzelDatei und zusätzliche, scopespezifische Dateien in Ordner haben.

## Struktur

Jede Datei hat zwei Teile:

1. [YAML Ain't Markup Language](https://yaml.org/) Frontmatter zwischen `---` Markierungen.
2. Markdown unter dem Frontmatter mit Produkt-, Publikum, Stimme- oder Domänenkontext.

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

Diensteanbieter-Credentials gehören in die Account-Einstellungen, niemals in `GLOSSIA.md`. Der optionale `model`-Wert ist ein Account-Modell-Griff.

## Frontmatter-Felder

| Feld | Typ | Erforderlich | Beschreibung |
|---|---|---|---|
| `source_language` | string | nein | Quell-Locale für diesen Scope. Standardwert ist `en`. |
| `model` | string | nein | Account-Modell-Griff. Glossia verwendet das Account-Standardwert, wenn nichts angegeben ist, und meldet einen Fehler, wenn ein expliziter Griff nicht existiert. |
| `sources` | map oder List | für eine top-level-Regel | Quelldatei-Muster. Map-Werte können Ausgabe-Vorlagen definieren. |
| `targets` | map oder List | wenn Quellen konfiguriert sind | Zielsprachen-Code-Codes. Eine Map kann eine Locale-Code mit einem Sprachnamen verbinden. |
| `output` | string | wenn keine Quellzuordnung oder `target_path` ein Ziel liefert | Ausgabe-Datei-Vorlage. |
| `target_path` | string | wenn keine Quellzuordnung oder `output` ein Ziel liefert | Basisverzeichnis-Vorlage für übersetzte Dateien. |
| `translate` | List | nein | Mehrere Übersetzungsregeln, jede mit ihren eigenen Quellen und optionalen Überschreibungen. |
| `exclude` | List | nein | Dateimuster, die übersprungen werden sollen. |
| `preserve` | List | nein | Inhalte, die unverändert bleiben müssen, wie Platzhalter oder Uniform Resource Locators. |
| `frontmatter` | string | nein | Standardmäßig `preserve` oder `translate`. |
| `prompt` | string | nein | Zusätzliche Anleitung für diesen Scope oder diese Regel. |
| `validation` | List | für Dateierweiterungen ohne integrierten Adapter | Ein Validierungsbefehl gefolgt von seinen Argumenten. Der Befehl erhält das Kandidatenobjekt an seinem realen Zielpfad und muss einen nicht-null-Status zurückgeben, wenn die Datei ungültig ist. |
| `check_cmd` | string | nein | Ein Prüfbefehl, der dem Übersetzungsworkflow zur Verfügung steht. |
| `check_cmds` | Map | nein | Benannte Prüfbefehle, die dem Übersetzungsworkflow zur Verfügung stehen. |
| `retries` | integer | nein | Anzahl der Wiederholungsversuche nach einem fehlgeschlagenen Check. Standardwert ist `2`. |
| `locale` | string | nein | Locale, das an ein localespezifisches Kontextdatei angehängt ist. |

Unbekannte Frontmatter-Felder werden ignorieren.

## Dateiformate

Glossia hat integrierte Handhabung für Markdown, JavaScript Object Notation, YAML Ain't Markup Language, Portable Object und Textdateien. Andere Datei-Erweiterungen scheitern bei der Planung, es sei denn, das anwendbare `GLOSSIA.md` deklariert einen `validation`-Befehl. Dies verhindert, dass ein proprietäres strukturiertes Format schweigsam als unbeschränkter Text behandelt wird.

Der Validierungsbefehl läuft, nachdem das Kandidatenobjekt vorübergehend zu seinem realen Zielpfad geschrieben wurde. Er kann den nativen Parser, Compiler oder Build-Befehl des Repositorys aufrufen. Glossia stellt das vorherige Ziel nach jedem Validierungsversuch wieder her und schreibt das akzeptierte Kandidatenobjekt erst danach.

## Quellzuordnungen

Die klarste Form κάθε\_Sourcemuster zu einer Ausgabe-Vorlage zuordnen:

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

Eine Liste verwendet jeweils den Locale-Code als Sprachkennzeichen: 

```yaml
targets:
  - es
  - ja
```

Eine Map kann einen lesbaren Sprachnamen hinzufügen: 

```yaml
targets:
  es: Spanish
  ja: Japanese
```

## Ausgabewerte 

| Variable | Wert |
|---|---|
| `{locale}` oder `{lang}` | Zielbereichs-Code. |
| `{relpath}` | Pfad der Quelldatei relativ zum übereinstimmenden Muster. |
| `{basename}` | Quelldateiname ohne Erweiterung. |
| `{ext}` | Dateierweiterung ohne führendes Punkt. |

## Mehrere Regeln 

Verwende `translate` wenn različných Inhaltgruppen unterschiedliche Ziele oder Prüfungen benötigen: 

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

Regelwerte überschreiben Werte, die vom umgebenden Dokument geerbt werden. 

## Begrenzter Kontext 

Glossia liest `GLOSSIA.md`-Dateien vom Repository-Wurzipfad hinweg bis zur Quelldatei: 

- Elterneinstellungen bieten Standards. 
- Eine tiefere Datei überschreibt Felder für ihr Verzeichnis. 
- Der Markdown-Kontext wird von Eltern nach Kind aufgebaut. 
- Zielbereichsspezifische Anweisungen und ein zielbereichsspezifischer Modellierungs-Handle können in `GLOSSIA/<locale>.md`. 

Dies ermöglicht es einem Repository, allgemeine Sprachanweisungen am Wurzelordner zu belassen, während produkt- oder zielbereichsspezifische Anweisungen in die Nähe des betroffenes Inhalts platziert werden.